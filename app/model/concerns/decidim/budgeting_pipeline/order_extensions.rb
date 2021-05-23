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

      included do
        has_many :confirmed_line_items, -> { confirmed }, class_name: "Decidim::Budgets::LineItem", foreign_key: "decidim_order_id", dependent: :destroy
        has_many :confirmed_projects, through: :confirmed_line_items, source: :project, class_name: "Decidim::Budgets::Project", foreign_key: "decidim_project_id"
      end

      # Public: Returns the sum of project budgets
      def confirmed_total_budget
        confirmed_projects.to_a.sum(&:budget_amount)
      end

      # Public: Returns the count of projects
      def confirmed_total_projects
        confirmed_projects.count
      end

      # Public: For budget voting returns the total budget and for project
      # selection voting, returns the amount of selected projects.
      def confirmed_total
        return confirmed_total_projects if projects_rule?

        confirmed_total_budget
      end

      # Public: Returns the order confirmed budget percent from the settings
      # total budget or the progress for selected projects if the selected
      # project rule is enabled
      def confirmed_budget_percent
        return (confirmed_total_projects.to_f / maximum_projects) * 100 if projects_rule?

        (confirmed_total_budget.to_f / budget.total_budget) * 100
      end

      # Public: Returns the allocation amount that is left to spend.
      def unused_confirmed_allocation
        amount =
          if projects_rule?
            maximum_projects - confirmed_total_projects
          else
            budget.total_budget - confirmed_total_budget
          end

        amount.positive? ? amount : 0
      end

      def confirmed_allocation_exceeded?
        return (maximum_projects - confirmed_total_projects).negative? if projects_rule?

        (budget.total_budget - confirmed_total_budget).negative?
      end

      def confirmed_rule_errors
        [].tap do |rules|
          rules << :allocation_exceeded if confirmed_allocation_exceeded?

          if projects_rule?
            rules << :minimum_projects if confirmed_total_projects < minimum_projects
            rules << :maximum_projects if confirmed_total_projects > maximum_projects
          elsif minimum_projects_rule?
            rules << :minimum_projects if confirmed_total_projects < minimum_projects
          else
            rules << :minimum_budget if confirmed_total_budget < minimum_budget
            rules << :maximum_budget if confirmed_total_budget > maximum_budget
          end
        end
      end

      def confirmed_valid?
        confirmed_rule_errors.none?
      end
    end
  end
end
