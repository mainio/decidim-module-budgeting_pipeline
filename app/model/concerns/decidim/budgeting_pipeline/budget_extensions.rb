# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    # Extends the budget class with some options.
    module BudgetExtensions
      extend ActiveSupport::Concern

      include Decidim::HasUploadValidations
      include Decidim::Stats::Measurable

      included do
        validates_upload :list_image, uploader: Decidim::Budgets::BudgetImageUploader
        has_one_attached :list_image
      end
    end
  end
end
