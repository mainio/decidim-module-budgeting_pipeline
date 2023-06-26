# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    autoload :ProjectLinkedResourceType, "decidim/api/project_linked_resource_type"

    module Api
      autoload :BudgetTypeExtensions, "decidim/budgeting_pipeline/api/types/budget_type_extensions"
      autoload :ProjectTypeExtensions, "decidim/budgeting_pipeline/api/types/project_type_extensions"
    end
  end
end
