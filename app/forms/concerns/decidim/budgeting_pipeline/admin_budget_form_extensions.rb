# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    # Adds the extra fields to the admin budget form.
    module AdminBudgetFormExtensions
      extend ActiveSupport::Concern

      included do
        attribute :center_latitude, Float
        attribute :center_longitude, Float

        def geocoded?
          center_latitude.present? && center_longitude.present?
        end
      end
    end
  end
end
