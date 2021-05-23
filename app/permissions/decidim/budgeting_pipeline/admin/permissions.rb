# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    module Admin
      class Permissions < Decidim::DefaultPermissions
        def permissions
          return permission_action if permission_action.scope != :admin

          case permission_action.subject
          when :help_section
            case permission_action.action
            when :create, :read
              allow!
            when :update, :delete
              toggle_allow(section)
            end
          end

          permission_action
        end

        private

        def section
          @section ||= context.fetch(:help_section, nil)
        end
      end
    end
  end
end
