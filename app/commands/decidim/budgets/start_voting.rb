# frozen_string_literal: true

module Decidim
  module Budgets
    # This command is executed when the user starts the voting process.
    class StartVoting < Decidim::Command
      def initialize(form, user, workflow)
        @form = form
        @user = user
        @workflow = workflow
      end

      # Destroys the help section if valid.
      #
      # Broadcasts :ok if successful, :invalid otherwise.
      def call
        return broadcast(:invalid) if form.invalid?

        # The user lock ensures that two orders are not created simultaneously
        # in case the user happens to start voting twice in a row concecutively
        # when served from different machines. This edge case can happen when
        # running under high concurrency and multiple machines at the same time.
        user.with_lock do
          destroy_previous_orders!
          create_orders!
        end

        broadcast(:ok, orders)
      end

      private

      attr_reader :form, :user, :workflow, :orders

      def destroy_previous_orders!
        Decidim::Budgets::Order.where(budget: budgets, user: user).where.not(
          budget: selected_budgets
        ).destroy_all
      end

      def create_orders!
        @orders = selected_budgets.map do |budget|
          Decidim::Budgets::Order.find_or_create_by!(user: user, budget: budget)
        end
      end

      def selected_budgets
        @selected_budgets ||= begin
          sticky_ids = []
          sticky_ids = workflow.sticky.map(&:id) if workflow.respond_to?(:sticky)

          budgets.where(id: sticky_ids + form.budget_ids)
        end
      end

      def budgets
        workflow.budgets
      end
    end
  end
end
