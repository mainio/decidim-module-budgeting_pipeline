# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    # Extends the action log model to add the "private-only" visibility type.
    module ActionLogExtensions
      extend ActiveSupport::Concern

      included do
        add_private_visibility_type!
      end

      class_methods do
        def add_private_visibility_type!
          validators_on(:visibility).each do |v|
            next unless v.is_a?(ActiveModel::Validations::InclusionValidator)
            break if v.options[:in].include?("private-only")

            v.options[:in] << "private-only"
          end
        end
      end
    end
  end
end
