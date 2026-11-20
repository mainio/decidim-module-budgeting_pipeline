# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    module BudgetsPermissionsExtensions
      extend ActiveSupport::Concern

      included do
        def public_action_allowed?
          return toggle_allow(true) if permission_action.subject == :results && permission_action.action == :read
          return false unless permission_action.subject == :project && permission_action.action == :read

          toggle_allow(project.nil? || project_accessible?)
        end

        def project_accessible?
          project&.visible? && (user&.admin? || (!project.deleted? && !project.budget.deleted?))
        end
      end
    end
  end
end
