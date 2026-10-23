# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    module BudgetsPermissionsExtensions
      extend ActiveSupport::Concern

      included do
        def public_action_allowed?
          return false unless permission_action.subject == :project && permission_action.action == :read

          toggle_allow(project&.visible? && (user&.admin? || (!project.deleted? && !project.budget.deleted?)))
        end
      end
    end
  end
end
