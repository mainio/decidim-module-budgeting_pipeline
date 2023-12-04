# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    module Api
      module ProjectTypeExtensions
        def self.included(type)
          # The budget_amount field is incorrectly camelized which is why we
          # remove it.
          type.own_fields.delete("budget_amount")

          type.include Decidim::Stats::StatsTypeExtension
          type.field :main_image, GraphQL::Types::String, "The main image URL for this project", null: true
          type.field :summary, Decidim::Core::TranslatedFieldType, "The summary for this project", null: true
          type.field :budget_amount, GraphQL::Types::Int, "The budget amount (maximum) for this project", null: true
          type.field :budget_amount, GraphQL::Types::Int, "DEPRECATED: (same as `budgetAmount`), use `budgetAmount` instead", null: true, camelize: false
          type.field :budget_amount_min, GraphQL::Types::Int, "The minimum budget amount for this project", null: true

          return unless Decidim::BudgetingPipeline.possible_project_linked_resources.any?

          type.field :linked_resources, [Decidim::BudgetingPipeline::ProjectLinkedResourceType], null: true do
            description "The linked resources for this project."
          end

          type.field :linking_resources, [Decidim::BudgetingPipeline::ProjectLinkedResourceType], null: true do
            description "The linking resources for this project."
          end
        end

        def main_image
          return unless object.main_image.attached?

          object.attached_uploader(:main_image).url
        end

        def linked_resources
          visible_resources(object.resource_links_from.map(&:to))
        end

        def linking_resources
          visible_resources(object.resource_links_to.map(&:from))
        end

        private

        def visible_resources(resources)
          visible = resources.reject do |resource|
            resource.nil? ||
              (resource.respond_to?(:published?) && !resource.published?) ||
              (resource.respond_to?(:hidden?) && resource.hidden?) ||
              (resource.respond_to?(:withdrawn?) && resource.withdrawn?)
          end
          return nil unless visible.any?

          visible
        end
      end
    end
  end
end
