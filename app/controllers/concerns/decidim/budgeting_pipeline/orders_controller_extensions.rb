# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    # Customizes the orders controller
    module OrdersControllerExtensions
      extend ActiveSupport::Concern

      include Decidim::BudgetingPipeline::OrdersUtilities
      include Decidim::BudgetingPipeline::ProjectItemUtilities # Overrides the `voted_for?` method for multiple orders.

      included do
        before_action :ensure_checked_out_orders!, only: [:index]
      end

      private

      def ensure_checked_out_orders!
        return redirect_to decidim.new_user_session_path unless user_signed_in?
        return if current_orders.any? && current_orders.all?(&:checked_out?)

        flash[:warning] = I18n.t("decidim.budgets.orders.index.not_voted")
        redirect_to EngineRouter.main_proxy(current_component).projects_path
      end
    end
  end
end
