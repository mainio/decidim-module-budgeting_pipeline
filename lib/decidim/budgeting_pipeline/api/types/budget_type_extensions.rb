# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    module Api
      module BudgetTypeExtensions
        def self.included(type)
          type.include Decidim::Stats::StatsTypeExtension

          type.field :result_page_content, Decidim::Core::TranslatedFieldType, "The result page content for this project", null: true
        end
      end
    end
  end
end
