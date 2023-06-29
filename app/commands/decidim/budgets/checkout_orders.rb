# frozen_string_literal: true

module Decidim
  module Budgets
    # A command with all the business to checkout all user's orders.
    class CheckoutOrders < Decidim::Command
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
        return broadcast(:invalid, orders) if orders.empty?
        return broadcast(:invalid, orders) if orders.any?(&:invalid?)

        # This ensures that if the user happens to submit their vote twice in a
        # row, the vote record won't be duplicated. It would not affect the
        # amount of votes for projects as the other duplicate vote gets "cleared
        # out" when the orders are mapped to the new vote but it would affect
        # the reporting of the ongoing voting.
        return broadcast(:ok, orders) if existing_vote.present?

        checkout_orders
        create_vote
        send_summary

        broadcast(:ok, orders)
      end

      private

      attr_reader :orders, :user, :vote

      def checkout_orders
        orders.each do |order|
          order.with_lock do
            order.update!(checked_out_at: Time.current)
          end
        end
      end

      def create_vote
        @vote = Decidim.traceability.create!(
          Decidim::Budgets::Vote,
          user,
          {
            component: orders.first.component,
            user: user,
            orders: orders
          },
          visibility: "private-only"
        )
      end

      def existing_vote
        @existing_vote ||= Decidim::Budgets::Vote.where(component: orders.first.component, user: user)
      end

      def send_summary
        Decidim::Budgets::SendOrderSummariesJob.perform_later(vote, user)
      end
    end
  end
end
