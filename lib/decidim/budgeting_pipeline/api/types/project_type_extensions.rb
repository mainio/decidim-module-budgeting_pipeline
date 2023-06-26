# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    module Api
      module ProjectTypeExtensions
        def self.included(type)
          type.implements Decidim::Core::CategorizableInterface
          type.implements Decidim::Core::ScopableInterface
          type.implements Decidim::Stats::StatsInterface

          if Decidim::BudgetingPipeline.possible_project_linked_resources.any?
            type.field :linked_resources, [Decidim::BudgetingPipeline::ProjectLinkedResourceType] do
              description "The linked resources for this project."
            end

            type.field :linking_resources, [Decidim::BudgetingPipeline::ProjectLinkedResourceType] do
              description "The linking resources for this project."
            end
          end
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
