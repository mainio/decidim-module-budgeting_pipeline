# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    # This module's job is to extend the API with custom fields related to
    # decidim-budgeting_pipeline.
    module MutationExtensions
      # Public: Extends a type with `decidim-budgeting_pipeline`'s fields.
      #
      # type - A GraphQL::BaseType to extend.
      #
      # Returns nothing.
      def self.included(type)
        type.field :budget, Decidim::BudgetingPipeline::BudgetMutationType, "A budget", null: false do
          argument :id, GraphQL::Types::ID, "The budget's id", required: false
        end
      end

      def budget(id:)
        Decidim::Budgets::Budget.find(id)
      end
    end
  end
end
