# frozen_string_literal: true

module Decidim
  module Budgets
    # A command with all the business to confirm line items for orders
    class ConfirmLineItem < Rectify::Command
      # Public: Initializes the command.
      #
      # form - The form that defines the confirm state
      # order - The current order for the user or nil if it is not created yet.
      # project - The the project to include in the order
      def initialize(form, order, project)
        @form = form
        @order = order
        @project = project
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid.
      # - :invalid if the there is an error.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) if voting_not_enabled? || order.checked_out? || line_item.blank?

        transaction do
          confirm_line_item
          broadcast(:ok, order)
        end
      end

      private

      attr_reader :form, :order, :project

      def confirm_line_item
        order.with_lock do
          line_item.update!(confirmed: form.confirmed)
        end
      end

      def line_item
        @line_item ||= order.line_items.find_by(project: project)
      end

      def voting_not_enabled?
        project.component.current_settings.votes != "enabled"
      end
    end
  end
end
