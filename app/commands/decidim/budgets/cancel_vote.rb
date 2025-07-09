# frozen_string_literal: true

module Decidim
  module Budgets
    # A command with all the business to cancel an order.
    class CancelVote < Decidim::Command
      # Public: Initializes the command.
      #
      # orders - The current orders for the user.
      def initialize(vote, user)
        @vote = vote
        @user = user
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid.
      # - :invalid if the there is an error.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) if invalid_orders?

        cancel_vote!
        broadcast(:ok, @orders)
      end

      private

      def invalid_orders?
        !@vote.orders.all?(&:checked_out?)
      end

      def cancel_vote!
        Decidim::Budgets::CancelledVote.cancel_vote!(@vote)
      end
    end
  end
end
