# frozen_string_literal: true

module Decidim
  module Budgets
    # This class holds a Form to confirm a line item in the budget.
    class ConfirmLineItemForm < Decidim::Form
      attribute :confirmed, Boolean, default: false

      def map_model(line_item)
        self.confirmed = line_item.confirmed?
      end
    end
  end
end
