# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    # Adds the extra fields to the admin project form.
    module AdminProjectFormExtensions
      extend ActiveSupport::Concern

      included do
        attribute :address, Decidim::Form::String
        attribute :latitude, Decidim::Form::Float
        attribute :longitude, Decidim::Form::Float
        attribute :main_image
        attribute :remove_main_image

        alias_method :component, :current_component

        validates :address, geocoding: true, if: ->(form) { form.has_address? && !form.geocoded? }
        validates :main_image, passthru: {
          to: Decidim::Budgets::Project,
          with: { component: ->(form) { form.current_component } }
        }

        # Temporary fix to fix the gallery attachment methods
        def photos
          return @photos_records if @photos_records

          return @photos unless @photos.is_a?(Array)

          @photos_records = @photos.map do |attachment|
            if attachment.is_a?(String) || attachment.is_a?(Integer)
              Decidim::Attachment.find_by(id: attachment)
            else
              attachment
            end
          end.compact
        end

        def geocoding_enabled?
          return false unless Decidim::Map.available?(:geocoding)

          current_component.settings.geocoding_enabled?
        end

        def has_address?
          geocoding_enabled? && address.present?
        end

        def geocoded?
          latitude.present? && longitude.present?
        end
      end
    end
  end
end
