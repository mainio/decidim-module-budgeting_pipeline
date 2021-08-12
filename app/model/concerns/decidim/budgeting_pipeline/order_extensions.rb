# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    # Extends the order class with some options.
    module OrderExtensions
      extend ActiveSupport::Concern

      class_methods do
        def order_by_budgets
          joins(:budget).order("decidim_budgets_budgets.weight")
        end
      end

      def allocation_available_for?(project)
        available = unused_allocation
        return available.positive? if projects_rule?

        available - project.budget_amount >= 0
      end

      # Public: Returns the allocation amount that is left to spend.
      def unused_allocation
        amount =
          if projects_rule?
            maximum_projects - total_projects
          else
            budget.total_budget - total_budget
          end

        amount.positive? ? amount : 0
      end

      def allocation_exceeded?
        return (maximum_projects - total_projects).negative? if projects_rule?

        (budget.total_budget - total_budget).negative?
      end

      def rule_errors
        [].tap do |rules|
          rules << :allocation_exceeded if allocation_exceeded?

          if projects_rule?
            rules << :minimum_projects if total_projects < minimum_projects
            rules << :maximum_projects if total_projects > maximum_projects
          elsif minimum_projects_rule?
            rules << :minimum_projects if total_projects < minimum_projects
          else
            rules << :minimum_budget if total_budget < minimum_budget
            rules << :maximum_budget if total_budget > maximum_budget
          end
        end
      end

      def valid_for_checkout?
        rule_errors.none?
      end
    end
  end
end
