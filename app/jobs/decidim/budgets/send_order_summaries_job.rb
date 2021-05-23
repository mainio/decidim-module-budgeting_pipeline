# frozen_string_literal: true

module Decidim
  module Budgets
    class SendOrderSummariesJob < ApplicationJob
      queue_as :default

      def perform(order_ids, user)
        return if user&.email.blank?

        orders = Decidim::Budgets::Order.where(id: order_ids)
        OrderSummariesMailer.order_summaries(orders, user).deliver_now
      end
    end
  end
end
