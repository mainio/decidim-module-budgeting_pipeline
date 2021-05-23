# frozen_string_literal: true

module Decidim
  module Budgets
    module Admin
      # This controller allows to create or update a budget.
      class HelpsController < Admin::ApplicationController
        helper_method :containers

        private

        def containers
          Decidim::BudgetingPipeline::HelpContainer.all
        end
      end
    end
  end
end
