# frozen_string_literal: true

module Decidim
  module Budgets
    # Controls the results view.
    class ResultsController < ApplicationController
      helper_method :budgets, :sticky_budgets, :common_budgets, :projects_with_votes, :minimum_project_budget, :vote_success?

      def show
        redirect_to projects_path unless current_settings.show_votes?
      end

      private

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

        @projects_with_votes[budget.id] = Decidim::Budgets::Project.where(budget: budget).joins(:orders).select(
          "decidim_budgets_projects.*, COUNT(decidim_budgets_orders.id) as votes_count"
        ).group("decidim_budgets_projects.id").order(votes_count: :desc)
      end

      def minimum_project_budget(budget)
        @minimum_project_budget ||= {}
        return @minimum_project_budget[budget.id] if @minimum_project_budget[budget.id].present?

        @minimum_project_budget[budget.id] = Decidim::Budgets::Project.where(budget: budget).minimum(:budget_amount)
      end

      def vote_success?
        @vote_success ||= session.delete("decidim-budgets.voted") == true
      end
    end
  end
end
