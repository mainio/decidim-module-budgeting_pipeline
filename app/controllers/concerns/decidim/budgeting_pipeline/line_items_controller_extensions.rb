# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    # Customizes the line items controller
    module LineItemsControllerExtensions
      extend ActiveSupport::Concern

      include Decidim::FormFactory
      include Decidim::BudgetingPipeline::OrdersController

      included do
        private

        def budget
          @budget ||= Decidim::Budgets::Budget.find(params[:budget_id])
        end
      end

      public

      def confirm
        @form = form(Decidim::Budgets::ConfirmLineItemForm).from_params(
          params[:line_item] || {}
        )

        respond_to do |format|
          Decidim::Budgets::ConfirmLineItem.call(@form, current_order, project) do
            on(:ok) do |_order|
              format.html { render nothing: true, status: :unprocessable_entity }
              format.js { render }
            end

            on(:invalid) do
              render nothing: true, status: :unprocessable_entity
            end
          end
        end
      end

      def confirm_all
        @form = form(Decidim::Budgets::ConfirmLineItemForm).from_params(
          params[:order] || {}
        )

        respond_to do |format|
          Decidim::Budgets::ConfirmAllLineItems.call(@form, current_order) do
            on(:ok) do |_order|
              format.html { render nothing: true, status: :unprocessable_entity }
              format.js { render "confirm" }
            end

            on(:invalid) do
              render nothing: true, status: :unprocessable_entity
            end
          end
        end
      end
    end
  end
end
