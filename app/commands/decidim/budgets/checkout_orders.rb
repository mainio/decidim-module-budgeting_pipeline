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

        # The user lock ensures that if the user happens to submit their vote
        # twice in a row, the vote record won't be duplicated. It would not
        # affect the amount of votes for projects as the other duplicate vote
        # gets "cleared out" when the orders are mapped to the new vote but it
        # would affect the reporting of the ongoing voting (i.e. the number of
        # empty votes would increase).
        user.with_lock do
          next if has_existing_vote?

          checkout_orders
          create_vote

          send_summary
        end

        broadcast(:ok, orders)
      rescue ActiveRecord::RecordInvalid
        # This would be the case if the order cannot be checked out e.g. because
        # it has too few projects.
        broadcast(:invalid, orders)
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

      def has_existing_vote?
        Decidim::Budgets::Vote.find_by(component: orders.first.component, user: user).present?
      end

      def send_summary
        Decidim::Budgets::SendOrderSummariesJob.perform_later(vote, user)
      end
    end
  end
end
