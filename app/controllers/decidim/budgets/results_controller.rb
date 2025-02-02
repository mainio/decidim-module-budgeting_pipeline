# frozen_string_literal: true

module Decidim
  module Budgets
    # Controls the results view.
    class ResultsController < ApplicationController
      include Decidim::TranslatableAttributes
      include Decidim::BudgetingPipeline::VoteUtilities

      helper_method :page_title, :budgets, :sticky_budgets, :common_budgets, :projects_with_votes, :minimum_project_budget, :maximum_project_budget, :vote_success?

      before_action :set_breadcrumbs, only: [:show]

      def show
        redirect_to EngineRouter.main_proxy(current_component).projects_path unless results_visible?

        @total_votes = Decidim::Budgets::Order.finished.where(budget: budgets).count(:decidim_budgets_vote_id)
      end

      private

      def results_visible?
        # Allow admins to see the results page in advance so that we can check
        # that the results are displayed correctly before they are published.
        return true if voting_finished? && current_user&.admin?

        current_settings.show_votes?
      end

      def page_title
        @page_title ||= begin
          title = translated_attribute(component_settings.results_page_title).strip
          title.presence || t("decidim.budgets.results.show.title", service_name: current_organization.name)
        end
      end

      def set_breadcrumbs
        return unless respond_to?(:add_breadcrumb, true)

        add_breadcrumb(page_title, results_path)
      end

      def budgets
        current_workflow.budgets
      end

      def sticky_budgets
        @sticky_budgets ||=
          if current_workflow.respond_to?(:sticky)
            current_workflow.sticky
          else
            []
          end
      end

      # These are all budgets except the sticky one(s) that will show on the
      # top.
      def common_budgets
        @common_budgets ||= begin
          sticky_ids = sticky_budgets.map(&:id)
          current_workflow.budgets.reject do |budget|
            sticky_ids.include?(budget.id)
          end
        end
      end

      def projects_with_votes(budget)
        @projects_with_votes ||= {}
        return @projects_with_votes[budget.id] if @projects_with_votes[budget.id].present?

        @projects_with_votes[budget.id] = Decidim::Budgets::Project.where(budget:).order_by_most_voted(only_voted: true).select(
          "decidim_budgets_projects.*",
          "decidim_budgets_projects_with_votes.votes_count"
        )
      end

      def minimum_project_budget(budget)
        @minimum_project_budget ||= {}
        return @minimum_project_budget[budget.id] if @minimum_project_budget[budget.id].present?

        @minimum_project_budget[budget.id] = Decidim::Budgets::Project.where(budget:).minimum(:budget_amount)
      end

      def maximum_project_budget(budget)
        @maximum_project_budget ||= {}
        return @maximum_project_budget[budget.id] if @maximum_project_budget[budget.id].present?

        @maximum_project_budget[budget.id] = Decidim::Budgets::Project.where(budget:).maximum(:budget_amount)
      end

      def vote_success?
        @vote_success ||= current_workflow.voted.any?
      end
    end
  end
end
