# frozen_string_literal: true

module Decidim
  module Budgets
    # A command with all the business to confirm all line items for orders
    class ConfirmAllLineItems < Rectify::Command
      # Public: Initializes the command.
      #
      # form - The form that defines the confirm state
      # order - The current order for the user or nil if it is not created yet.
      def initialize(form, order)
        @form = form
        @order = order
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid.
      # - :invalid if the there is an error.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) if voting_not_enabled? || order.checked_out?

        transaction do
          confirm_line_items
          broadcast(:ok, order)
        end
      end

      private

      attr_reader :form, :order

      def confirm_line_items
        order.with_lock do
          order.line_items.each do |line_item|
            line_item.update!(confirmed: form.confirmed)
          end
        end
      end

      def voting_not_enabled?
        order.budget.component.current_settings.votes != "enabled"
      end
    end
  end
end
