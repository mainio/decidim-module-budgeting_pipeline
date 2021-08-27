# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    # Customizes the orders controller
    module OrdersControllerExtensions
      extend ActiveSupport::Concern

      include Decidim::BudgetingPipeline::OrdersUtilities
      include Decidim::BudgetingPipeline::ProjectItemUtilities # Overrides the `voted_for?` method for multiple orders.

      included do
        before_action :ensure_orders!, only: [:index]
      end

      private

      def ensure_orders!
        return if current_user && current_orders.any?

        flash[:warning] = I18n.t("decidim.budgets.orders.index.not_voted")
        redirect_to projects_path
      end
    end
  end
end
