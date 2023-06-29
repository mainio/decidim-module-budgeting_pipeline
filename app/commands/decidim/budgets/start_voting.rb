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

        destroy_previous_orders!
        create_orders!

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
        @orders = [].tap do |ords|
          selected_budgets.each do |budget|
            ords << order_for(budget)
          end
        end
      end

      def order_for(budget)
        Decidim::Budgets::Order.find_by(user: user, budget: budget) ||
          Decidim::Budgets::Order.create!(user: user, budget: budget)
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
