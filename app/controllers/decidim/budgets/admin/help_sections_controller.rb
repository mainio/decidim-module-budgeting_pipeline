# frozen_string_literal: true

module Decidim
  module Budgets
    module Admin
      # This controller allows to create or update a budget.
      class HelpSectionsController < Admin::ApplicationController
        helper_method :container, :sections

        before_action :ensure_container!

        def permission_class_chain
          [Decidim::BudgetingPipeline::Admin::Permissions] + super
        end

        def new
          enforce_permission_to :create, :help_section
          @form = form(HelpSectionForm).instance
        end

        def edit
          enforce_permission_to :update, :help_section, help_section: section
          @form = form(HelpSectionForm).from_model(section)
        end

        def create
          enforce_permission_to :create, :help_section
          @form = form(HelpSectionForm).from_params(params, current_component:)

          CreateHelpSection.call(@form, container) do
            on(:ok) do
              flash[:notice] = I18n.t("help_sections.create.success", scope: "decidim.budgets.admin")
              redirect_to help_sections_path(container.key)
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("help_sections.create.invalid", scope: "decidim.budgets.admin")
              render action: "new"
            end
          end
        end

        def update
          enforce_permission_to :update, :help_section, help_section: section
          @form = form(HelpSectionForm).from_params(params, current_component:)

          UpdateHelpSection.call(@form, section) do
            on(:ok) do
              flash[:notice] = I18n.t("help_sections.update.success", scope: "decidim.budgets.admin")
              redirect_to help_sections_path(container.key)
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("help_sections.update.invalid", scope: "decidim.budgets.admin")
              render action: "edit"
            end
          end
        end

        def destroy
          enforce_permission_to :delete, :help_section, help_section: section

          DestroyHelpSection.call(section, current_user) do
            on(:ok) do
              flash[:notice] = I18n.t("help_sections.destroy.success", scope: "decidim.budgets.admin")
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("help_sections.destroy.invalid", scope: "decidim.budgets.admin")
            end
          end

          redirect_to help_sections_path(container.key)
        end

        private

        def ensure_container!
          raise ActionController::RoutingError, "Not Found" unless container
        end

        def container
          @container ||= Decidim::BudgetingPipeline::HelpContainer.find(params[:help_key])
        end

        def sections
          @sections ||= Decidim::Budgets::HelpSection.where(
            component: current_component,
            key: container.key
          ).order(weight: :asc)
        end

        def section
          @section ||= sections.find_by(id: params[:id])
        end
      end
    end
  end
end
