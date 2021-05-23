# frozen_string_literal: true

module Decidim
  module Budgets
    # This class holds a Form to select the budget/s to vote on.
    class BudgetSelectForm < Decidim::Form
      attribute :budget_ids, [Integer], default: []

      validates :budget_ids, presence: true

      def map_model(workflow)
        return unless workflow.respond_to?(:suggested)

        self.budget_ids = workflow.suggested.map(&:id)
      end
    end
  end
end
