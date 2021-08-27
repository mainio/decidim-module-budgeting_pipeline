# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    # Adds the abilitity for controller to fetch the user's orders.
    module OrdersUtilities
      extend ActiveSupport::Concern

      included do
        helper_method :current_orders, :can_cast_votes?
      end

      private

      def current_orders
        @current_orders ||= Decidim::Budgets::Order.where(
          user: current_user,
          budget: current_workflow.budgets
        ).order_by_budgets
      end

      def can_cast_votes?
        return current_workflow.can_cast_votes? if current_workflow.respond_to?(:can_cast_votes?)

        current_orders.any? && current_orders.all?(&:valid_for_checkout?)
      end
    end
  end
end
