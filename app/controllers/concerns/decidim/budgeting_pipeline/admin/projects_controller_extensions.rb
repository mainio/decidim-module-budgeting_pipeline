# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    module Admin
      # Customizes the admin projects controller
      module ProjectsControllerExtensions
        extend ActiveSupport::Concern

        included do
          # Overrides the underlying `project` method to avoid storing the
          # memorized project to a variable named `@project` because it breaks
          # the upload fields. This happens because the ActionView tag helpers
          # are trying to fetch the correct record based on the passed object
          # name when fields are created without a scoped form helper, such as
          # the "remove" field for the file upload field. This causes the form
          # to break because the original `Decidim::Budgets::Project` record
          # does not respond to `:remove_main_image`.
          #
          # This should be revisited after migrating to the dynamic upload
          # fields.
          alias_method :project, :current_project

          private :project
        end

        private

        def current_project
          @current_project ||= projects.find(params[:id])
        end
      end
    end
  end
end
