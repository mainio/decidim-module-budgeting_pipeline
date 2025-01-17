# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    # Adds the extra fields to the admin budget form.
    module AdminBudgetFormExtensions
      extend ActiveSupport::Concern

      included do
        attribute :center_latitude, Float
        attribute :center_longitude, Float
        attribute :list_image, Decidim::Attributes::Blob

        validates :list_image, passthru: {
          to: Decidim::Budgets::Budget,
          with: {
            # When the image validations are done through the validation
            # endpoint, the component is unknown and would cause the
            # validations to fail because the component would not exist.
            component: lambda do |form|
              Decidim::Component.new(
                participatory_space: Decidim::ParticipatoryProcess.new(
                  organization: form.current_organization
                )
              )
            end
          }
        }

        def geocoded?
          center_latitude.present? && center_longitude.present?
        end
      end
    end
  end
end
