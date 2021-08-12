# frozen_string_literal: true

module Decidim
  module Budgets
    # A command with all the business to checkout all user's orders.
    class CheckoutOrders < Rectify::Command
      # Public: Initializes the command.
      #
      # orders - The current orders for the user.
      def initialize(orders, user)
        @orders = orders
        @user = user
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid.
      # - :invalid if the there is an error.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid, orders) if orders.any?(&:invalid?)

        checkout_orders
        send_summary

        broadcast(:ok, orders)
      end

      private

      attr_reader :orders, :user

      def checkout_orders
        orders.each do |order|
          order.with_lock do
            order.checked_out_at = Time.current
            order.save
          end
        end
      end

      def send_summary
        Decidim::Budgets::SendOrderSummariesJob.perform_later(orders.map(&:id), user)
      end
    end
  end
end
