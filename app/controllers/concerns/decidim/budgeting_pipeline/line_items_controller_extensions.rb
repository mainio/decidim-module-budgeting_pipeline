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
        def create
          enforce_permission_to :vote, :project, project: project, budget: budget, workflow: current_workflow

          respond_to do |format|
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
