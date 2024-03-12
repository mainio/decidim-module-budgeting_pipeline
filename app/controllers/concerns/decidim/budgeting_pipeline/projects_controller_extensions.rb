# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    # Customizes the main projects controller
    module ProjectsControllerExtensions
      extend ActiveSupport::Concern

      include Decidim::Paginable
      include Decidim::TranslatableAttributes
      include Decidim::BudgetingPipeline::VoteUtilities
      include Decidim::BudgetingPipeline::OrdersUtilities
      include Decidim::BudgetingPipeline::Authorizable
      include Decidim::BudgetingPipeline::Orderable

      included do
        before_action :set_breadcrumbs, only: [:index, :show]

        helper_method :authorization_required?, :user_authorized?, :help_sections, :geocoded_projects, :budgets, :maximum_project_budget, :vote_success?

        helper Decidim::BudgetingPipeline::AuthorizationHelper

        def index; end

        def show
          raise ActionController::RoutingError, "Not Found" unless project
        end

        def default_filter_params
          {
            search_text_cont: "",
            with_any_status: %w(all),
            with_any_scope: default_filter_scope_params,
            with_any_category: "all",
            decidim_budgets_budget_id_eq: nil,
            budget_amount_gteq: 0,
            budget_amount_lteq: maximum_project_budget,
            favorites: nil,
            selected: nil
          }
        end

        def search_collection
          Decidim::Budgets::Project.joins(:budget).where(
            decidim_budgets_budgets: { decidim_component_id: current_component.id }
          ).includes([:scope, :component, :category])
        end

        def project
          @project ||= Decidim::Budgets::Project.find_by(id: params[:id], budget: budgets)
        end

        private :search_collection, :default_filter_params, :project
      end

      private

      def set_breadcrumbs
        return unless respond_to?(:add_breadcrumb, true)

        add_breadcrumb(t("decidim.budgets.projects.index.breadcrumb"), projects_path)
        return unless action_name == "show"
        return unless project

        add_breadcrumb(translated_attribute(project.title), project_path(project))
      end

      def help_sections
        @help_sections ||= Decidim::Budgets::HelpSection.where(
          component: current_component,
          key: "index"
        ).order(:weight)
      end

      def geocoded_projects
        @geocoded_projects ||= begin
          base_query = search.result
          base_query.geocoded_data_for(current_component)
        end
      end

      def budgets
        @budgets ||= Decidim::Budgets::Budget.where(component: current_component).order(weight: :asc)
      end

      def maximum_project_budget
        @maximum_project_budget ||= Decidim::Budgets::Project.where(budget: budgets).maximum(:budget_amount)
      end

      def vote_success?
        @vote_success ||= session.delete("decidim-budgets.voted") == true
      end
    end
  end
end
