# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    module Admin
      # Customizes the admin projects controller to fix a bug on passing the
      # budget through the form context.
      module ProjectsControllerExtensions
        extend ActiveSupport::Concern

        included do
          def new
            enforce_permission_to :create, :project
            @form = form(Decidim::Budgets::Admin::ProjectForm).from_params(
              { attachment: form(AttachmentForm).instance },
              budget: budget
            )
          end

          def edit
            enforce_permission_to :update, :project, project: project
            @form = form(Decidim::Budgets::Admin::ProjectForm).from_model(project, budget: budget)
            @form.attachment = form(AttachmentForm).instance
          end
        end
      end
    end
  end
end
