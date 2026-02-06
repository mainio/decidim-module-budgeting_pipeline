# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    # This module customizes the project serialization to add extra data to the
    # exports.
    module ProjectSerializerExtensions
      extend ActiveSupport::Concern

      included do
        alias_method :serialize_orig_budgeting_pipeline, :serialize unless method_defined?(:serialize_orig_budgeting_pipeline)

        def serialize
          serialize_orig_budgeting_pipeline.merge(budgeting_pipeline_serialize_data)
        end
      end

      private

      def budgeting_pipeline_serialize_data
        {
          budget_amount_min: project.budget_amount_min,
          answer: project.answer
        }
      end
    end
  end
end
