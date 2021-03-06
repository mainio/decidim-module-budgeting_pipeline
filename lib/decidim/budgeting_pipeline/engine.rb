# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    # This is an engine that controls the budgeting pipeline functionality.
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::BudgetingPipeline

      initializer "decidim_budgeting_pipeline.component_settings" do
        Decidim.find_component_manifest(:budgets).tap do |component|
          component.admin_stylesheet = "decidim/budgeting_pipeline/admin/budgets"
          component.settings(:global) do |settings|
            # Enable editor content for the more information modal
            more_information = settings.attributes[:more_information_modal]
            more_information.editor = true

            # Add extra attributes
            settings.attribute :vote_projects_per_page, type: :integer, default: 6
            settings.attribute :more_information_modal_label, type: :string, translated: true
            settings.attribute :geocoding_enabled, type: :boolean
            settings.attribute :default_map_center_coordinates, type: :string
            settings.attribute :vote_identify_page_content, type: :text, translated: true, editor: true
            settings.attribute :vote_identify_page_more_information, type: :text, translated: true, editor: true
            settings.attribute :vote_identify_invalid_authorization_title, type: :string, translated: true
            settings.attribute :vote_identify_invalid_authorization_content, type: :text, translated: true, editor: true
            settings.attribute :vote_budgets_page_content, type: :text, translated: true, editor: true
            settings.attribute :vote_projects_page_content, type: :text, translated: true, editor: true
            settings.attribute :vote_preview_page_content, type: :text, translated: true, editor: true
            settings.attribute :vote_success_content, type: :text, translated: true, editor: true
            settings.attribute :results_page_content, type: :text, translated: true, editor: true

            # Create the settings manipulator for moving the attributes
            m = Decidim::BudgetingPipeline::SettingsManipulator.new(settings)

            # Move the voting projects per page after the default projects per
            # page setting so it is in a logic position.
            m.move_attribute_after(:vote_projects_per_page, :projects_per_page)

            # Move the more information modal label before the modal content so
            # it is in a logic position.
            m.move_attribute_before(:more_information_modal_label, :more_information_modal)
          end

          component.settings(:step) do |settings|
            # Remove the more information modal from the step settings as it is
            # not needed there.
            settings.attributes.delete(:more_information_modal)
          end
        end
      end

      initializer "decidim_budgeting_pipeline.mount_routes" do
        Decidim::Budgets::Engine.routes.prepend do
          resources :projects, only: [:index, :show]

          resource :vote, only: [:show, :create] do
            get :budgets
            post :start
            get :projects
            get :preview
          end

          resources :orders, only: [:index]

          resources :budgets, only: [] do
            resource :order, only: [] do
              resource :line_item, only: [] do
                put :confirm
                put :confirm_all
              end
            end
          end

          resource :results, only: [:show]

          # Change the component root to the projects index
          root to: "projects#index"
        end
      end

      initializer "decidim_budgeting_pipeline.assets" do |app|
        app.config.assets.precompile += %w(decidim_budgeting_pipeline_manifest.js)
      end

      initializer "decidim_budgeting_pipeline.add_cells_view_paths", before: "decidim_budgets.add_cells_view_paths" do
        Cell::ViewModel.view_paths << File.expand_path("#{Decidim::BudgetingPipeline::Engine.root}/app/cells")
        Cell::ViewModel.view_paths << File.expand_path("#{Decidim::BudgetingPipeline::Engine.root}/app/views") # for partials
      end

      initializer "decidim_budgeting_pipeline.workflow_extensions" do
        # Customize the base workflow
        Decidim::Budgets::Workflows::Base.include(
          Decidim::BudgetingPipeline::Workflows::BaseExtensions
        )
      end

      initializer "decidim_budgeting_pipeline.api_extensions" do
        # TODO: Update to 0.24+
        Decidim::Budgets::BudgetType.define do
          interfaces [-> { Decidim::Stats::StatsInterface }]
        end
        Decidim::Budgets::ProjectType.define do
          interfaces [
            -> { Decidim::Core::CategorizableInterface },
            -> { Decidim::Core::ScopableInterface },
            -> { Decidim::Stats::StatsInterface }
          ]

          # These are the resources that are linked from the related object to the
          # idea.
          if Decidim::BudgetingPipeline.possible_project_linked_resources.any?
            visible_resources = lambda { |resources|
              resources = resources.reject do |resource|
                resource.nil? ||
                  (resource.respond_to?(:published?) && !resource.published?) ||
                  (resource.respond_to?(:hidden?) && resource.hidden?) ||
                  (resource.respond_to?(:withdrawn?) && resource.withdrawn?)
              end
              return nil unless resources.any?

              resources
            }

            field :linkedResources, types[Decidim::BudgetingPipeline::ProjectLinkedResourceType] do
              description "The linked resources for this project."
              resolve lambda { |object, _args, _ctx|
                visible_resources.call(object.resource_links_from.map(&:to))
              }
            end

            field :linkingResources, types[Decidim::BudgetingPipeline::ProjectLinkedResourceType] do
              description "The linking resources for this project."
              resolve lambda { |object, _args, _ctx|
                visible_resources.call(object.resource_links_to.map(&:from))
              }
            end
          end
        end
      end

      config.to_prepare do
        # Helper extensions
        Decidim::Budgets::ApplicationHelper.include(
          Decidim::BudgetingPipeline::ApplicationHelperExtensions
        )
        Decidim::Budgets::ProjectsHelper.include(
          Decidim::BudgetingPipeline::ProjectsHelperExtensions
        )

        # Controller extensions
        Decidim::Budgets::ProjectsController.include(
          Decidim::BudgetingPipeline::ProjectsControllerExtensions
        )
        Decidim::Budgets::LineItemsController.include(
          Decidim::BudgetingPipeline::LineItemsControllerExtensions
        )
        Decidim::Budgets::OrdersController.include(
          Decidim::BudgetingPipeline::OrdersControllerExtensions
        )
        Decidim::Budgets::Admin::BudgetsController.include(
          Decidim::BudgetingPipeline::Admin::BudgetsControllerExtensions
        )

        # Cell extensions
        Decidim::Budgets::ProjectMCell.include(
          Decidim::BudgetingPipeline::ProjectMCellExtensions
        )
        Decidim::Budgets::ProjectListItemCell.include(
          Decidim::BudgetingPipeline::ProjectListItemCellExtensions
        )

        # Form extensions
        Decidim::Budgets::Admin::ComponentForm.include(
          Decidim::BudgetingPipeline::AdminComponentFormExtensions
        )
        Decidim::Budgets::Admin::BudgetForm.include(
          Decidim::BudgetingPipeline::AdminBudgetFormExtensions
        )
        Decidim::Budgets::Admin::ProjectForm.include(
          Decidim::BudgetingPipeline::AdminProjectFormExtensions
        )

        # Command extensions
        Decidim::Budgets::AddLineItem.include(
          Decidim::BudgetingPipeline::AddLineItemExtensions
        )
        Decidim::Budgets::Admin::CreateBudget.include(
          Decidim::BudgetingPipeline::AdminCreateBudgetExtensions
        )
        Decidim::Budgets::Admin::UpdateBudget.include(
          Decidim::BudgetingPipeline::AdminUpdateBudgetExtensions
        )
        Decidim::Budgets::Admin::CreateProject.include(
          Decidim::BudgetingPipeline::AdminCreateProjectExtensions
        )
        Decidim::Budgets::Admin::UpdateProject.include(
          Decidim::BudgetingPipeline::AdminUpdateProjectExtensions
        )

        # Model extensions
        Decidim::ActionLog.include(
          Decidim::BudgetingPipeline::ActionLogExtensions
        )
        Decidim::Budgets::Budget.include(
          Decidim::Stats::Measurable
        )
        Decidim::Budgets::Project.include(
          Decidim::BudgetingPipeline::ProjectExtensions
        )
        Decidim::Budgets::Order.include(
          Decidim::BudgetingPipeline::OrderExtensions
        )
        Decidim::Budgets::LineItem.include(
          Decidim::BudgetingPipeline::LineItemExtensions
        )

        # Services extensions
        Decidim::Budgets::ProjectSearch.include(
          Decidim::BudgetingPipeline::ProjectSearchExtensions
        )
      end
    end
  end
end
