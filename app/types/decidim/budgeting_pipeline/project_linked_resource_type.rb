# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    # The ProjectLinkedResource subject type creates the linked resource
    # information for the project objects.
    ProjectLinkedResourceType = GraphQL::UnionType.define do
      possible_types Decidim::BudgetingPipeline.possible_project_linked_resources

      name "ProjectLinkedResource"
      description "A linked resource for the project"

      resolve_type ->(object, _context) { "#{object.class}Type".constantize }
    end
  end
end
