# frozen_string_literal: true

# Adds the extra data to projects.
module Decidim
  module BudgetingPipeline
    module AdminCreateProjectExtensions
      extend ActiveSupport::Concern

      included do
        def create_project!
          attributes = {
            budget: form.budget,
            scope: form.scope,
            category: form.category,
            title: form.title,
            summary: form.summary,
            description: form.description,
            budget_amount: form.budget_amount,
            address: form.address,
            latitude: form.latitude,
            longitude: form.longitude,
            main_image: form.main_image,
            remove_main_image: form.remove_main_image
          }

          @project = Decidim.traceability.create!(
            Decidim::Budgets::Project,
            form.current_user,
            attributes,
            visibility: "all"
          )
          @attached_to = @project
        end
      end
    end
  end
end
