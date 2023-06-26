# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    # The ProjectLinkedResource subject type creates the linked resource
    # information for the project objects.
    class ProjectLinkedResourceType < GraphQL::Schema::Union
      possible_types(*Decidim::BudgetingPipeline.possible_project_linked_resources)

      graphql_name "ProjectLinkedResource"
      description "A linked resource for the project"

      def self.resolve_type(obj, _ctx)
        "#{obj.class.name}Type".constantize
      end
    end
  end
end
