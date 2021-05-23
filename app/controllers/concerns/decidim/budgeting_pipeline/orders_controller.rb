# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    # Adds the abilitity for controller to fetch the user's orders.
    module OrdersController
      extend ActiveSupport::Concern

      included do
        helper_method :current_orders
      end

      private

      def current_orders
        @current_orders ||= Decidim::Budgets::Order.where(
          user: current_user,
          budget: current_workflow.budgets
        ).order_by_budgets
      end
    end
  end
end
