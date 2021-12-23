# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    module Admin
      # Customizes the admin budgets controller
      module BudgetsControllerExtensions
        extend ActiveSupport::Concern

        included do
          def permission_class_chain
            [Decidim::BudgetingPipeline::Admin::Permissions] + super
          end
        end
      end
    end
  end
end
