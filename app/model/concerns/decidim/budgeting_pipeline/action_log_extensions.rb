# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    # Extends the action log model to add the "private-only" visibility type.
    module ActionLogExtensions
      extend ActiveSupport::Concern

      included do
        def self.private_resource_types
          @private_resource_types ||= %w(
            Decidim::Budgets::Order
            Decidim::Budgets::Vote
          ).select { |klass| klass.safe_constantize.present? }
        end
      end
    end
  end
end
