# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    module Api
      module BudgetTypeExtensions
        def self.included(type)
          type.include Decidim::Stats::StatsTypeExtension
        end
      end
    end
  end
end
