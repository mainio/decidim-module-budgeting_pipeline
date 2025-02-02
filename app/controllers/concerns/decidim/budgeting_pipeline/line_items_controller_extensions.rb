# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    # Customizes the line items controller
    module LineItemsControllerExtensions
      extend ActiveSupport::Concern

      include Decidim::FormFactory
      include Decidim::BudgetingPipeline::OrdersUtilities
      include Decidim::BudgetingPipeline::ProjectItemUtilities # Overrides the `voted_for?` method for multiple orders.

      included do
        helper Decidim::Budgets::VotesHelper

        def create
          enforce_permission_to :vote, :project, project:, budget:, workflow: current_workflow

          @added = true

          respond_to do |format|
            # Note that the user-specific lock here is important in order to
            # prevent multiple simultaneous processes on different machines from
            # creating multiple orders for the same user in case the button is
            # pressed multiple times.
            current_user.with_lock do
              Decidim::Budgets::AddLineItem.call(persisted_current_order, project, current_user) do
                on(:ok) do |order|
                  self.current_order = order
                  reset_current_orders
                  format.html { redirect_back(fallback_location: Decidim::ResourceLocatorPresenter.new(budget).path) }
                  format.js { render "update_budget" }
                end

                on(:invalid) do |reason|
                  format.html { render plain: "", status: :unprocessable_entity }
                  format.js { create_error(reason) }
                end
              end
            end
          end
        end

        def destroy
          respond_to do |format|
            # Note that the user-specific lock here is important in order to
            # prevent multiple simultaneous processes on different machines from
            # creating multiple orders for the same user in case the button is
            # pressed multiple times.
            current_user.with_lock do
              Decidim::Budgets::RemoveLineItem.call(current_order, project) do
                on(:ok) do |_order|
                  format.html { redirect_back(fallback_location: budget_path(budget)) }
                  format.js { render "update_budget" }
                end

                on(:invalid) do
                  format.js { render "update_budget", status: :unprocessable_entity }
                end
              end
            end
          end
        end

        private

        def budget
          @budget ||= Decidim::Budgets::Budget.find(params[:budget_id])
        end

        def create_error(reason)
          @error_reason = reason
          render "update_budget_error"
        end

        def reset_current_orders
          # Forces to reload the orders and the workflow so that it has
          # up-to-date information about the orders and ability to proceed to
          # checkout.
          @current_orders = nil
          @current_workflow = nil
        end
      end
    end
  end
end
