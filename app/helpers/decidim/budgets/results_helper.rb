# frozen_string_literal: true

module Decidim
  module Budgets
    module ResultsHelper
      include Decidim::BudgetingPipeline::TextUtilities

      def winning_projects(budget)
        total_available = budget.total_budget

        [].tap do |projects|
          projects_with_votes(budget).each do |project|
            break if project.votes_count < 1

            if (total_available - project.budget_amount).positive?
              projects << project
              total_available -= project.budget_amount
            end

            break if total_available < minimum_project_budget(budget)
          end
        end
      end

      def top_projects(budget, amount: 10)
        projects_with_votes(budget).limit(amount)
      end

      def display_amounts_for?(budget)
        max = maximum_project_budget(budget)
        max && max.positive?
      end
    end
  end
end
