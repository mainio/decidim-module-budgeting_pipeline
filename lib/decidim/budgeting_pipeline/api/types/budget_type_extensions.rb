# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    module Api
      module BudgetTypeExtensions
        def self.included(type)
          type.implements Decidim::Stats::StatsInterface
        end
      end
    end
  end
end
