# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    module Workflows
      # Modifies the base workflow to include empty orders as well within the
      # workflow orders.
      module BaseExtensions
        extend ActiveSupport::Concern

        included do
          protected

          # Override orders to include empty orders because people can checkout
          # empty orders and also all orders need to be included when checking
          # for their checkout validity.
          def orders
            @orders ||= Decidim::Budgets::Order.includes(:projects).where(decidim_user_id: user, decidim_budgets_budget_id: budgets).map do |order|
              [order.decidim_budgets_budget_id, { order:, status: order.checked_out? ? :voted : :progress }]
            end.compact.to_h
          end
        end
      end
    end
  end
end
