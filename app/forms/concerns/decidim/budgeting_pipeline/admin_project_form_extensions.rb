# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    # Adds the extra fields to the admin project form.
    module AdminProjectFormExtensions
      extend ActiveSupport::Concern

      include Decidim::HasUploadValidations

      class_methods do
        def remove_budget_amount_validation!
          validators_on(:budget_amount).each do |v|
            v.attributes.delete(:budget_amount)
          end
        end
      end

      included do
        alias_method :map_model_orig_budgeting_pipeline, :map_model unless method_defined?(:map_model_orig_budgeting_pipeline)

        translatable_attribute :summary, String
        attribute :budget_amount_min, Integer
        attribute :address, String
        attribute :latitude, Float
        attribute :longitude, Float
        attribute :main_image, Decidim::Attributes::Blob
        attribute :remove_main_image, Decidim::AttributeObject::Model::Boolean, default: false
        attribute :idea_ids, Array[Integer]
        attribute :plan_ids, Array[Integer]

        alias_method :component, :current_component

        remove_budget_amount_validation!

        validates :budget_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
        validates :budget_amount_min, numericality: { greater_than_or_equal_to: 0 }, if: ->(form) { form.budget_amount_min.present? }
        validates :address, geocoding: true, if: ->(form) { form.has_address? && !form.geocoded? }
        validates :main_image, passthru: {
          to: Decidim::Budgets::Project,
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

        def map_model(model)
          map_model_orig_budgeting_pipeline(model)

          self.idea_ids = model.linked_resources(:ideas, "included_ideas").pluck(:id)
          self.plan_ids = model.linked_resources(:plans, "included_plans").pluck(:id)
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

      def ideas
        return [] unless defined?(Decidim::Ideas::Idea)

        @ideas ||= Decidim.find_resource_manifest(:ideas).try(:resource_scope, current_component)
                       &.where(id: idea_ids)
                       &.order(title: :asc)
      end

      def plans
        return [] unless defined?(Decidim::Plans::Plan)

        @plans ||= Decidim.find_resource_manifest(:plans).try(:resource_scope, current_component)
                       &.where(id: plan_ids)
                       &.order(title: :asc)
      end
    end
  end
end
