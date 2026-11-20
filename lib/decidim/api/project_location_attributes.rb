# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    class ProjectLocationAttributes < GraphQL::Schema::InputObject
      graphql_name "ProjectLocationAttributes"
      description "Attributes for defining a location for a project"

      argument :address, GraphQL::Types::String, "The street address of the project location.", required: false
      argument :latitude, GraphQL::Types::Float, "The latitude coordinate of the project location.", required: false
      argument :longitude, GraphQL::Types::Float, "The longitude coordinate of the project location.", required: false
    end
  end
end
