# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    # Customizes the orders controller
    module OrdersControllerExtensions
      extend ActiveSupport::Concern

      include Decidim::BudgetingPipeline::OrdersUtilities
      include Decidim::BudgetingPipeline::ProjectItemUtilities # Overrides the `voted_for?` method for multiple orders.
    end
  end
end
