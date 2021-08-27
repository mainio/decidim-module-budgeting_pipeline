# frozen_string_literal: true

module Decidim
  module Budgets
    class SendOrderSummariesJob < ApplicationJob
      queue_as :default

      def perform(vote, user)
        return if user&.email.blank?

        OrderSummariesMailer.order_summaries(vote.orders, user).deliver_now
      end
    end
  end
end
