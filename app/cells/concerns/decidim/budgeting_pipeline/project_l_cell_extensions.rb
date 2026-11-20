# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    # Customizes the project card cell
    module ProjectLCellExtensions
      extend ActiveSupport::Concern

      included do
        private

        def resource_title
          decidim_escape_translated model.title
        end
      end
    end
  end
end
