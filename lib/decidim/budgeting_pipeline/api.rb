# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    autoload :ProjectAttributes, "decidim/api/project_attributes"
    autoload :BudgetMutationType, "decidim/api/budget_mutation_type"
    autoload :ProjectLinkedResourceType, "decidim/api/project_linked_resource_type"
    autoload :ProjectLocationAttributes, "decidim/api/project_location_attributes"

    module Api
      autoload :Permissions, "decidim/budgeting_pipeline/api/permissions"

      autoload :BudgetTypeExtensions, "decidim/budgeting_pipeline/api/types/budget_type_extensions"
      autoload :ProjectTypeExtensions, "decidim/budgeting_pipeline/api/types/project_type_extensions"
    end
  end
end
