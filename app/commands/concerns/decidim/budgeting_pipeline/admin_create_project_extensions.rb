# frozen_string_literal: true

# Adds the extra data to projects.
module Decidim
  module BudgetingPipeline
    module AdminCreateProjectExtensions
      extend ActiveSupport::Concern

      include Decidim::AttachmentAttributesMethods

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
            longitude: form.longitude
          }.merge(attachment_attributes(:main_image))

          @project = Decidim.traceability.create!(
            Decidim::Budgets::Project,
            form.current_user,
            attributes,
            visibility: "all"
          )
          @attached_to = @project

          link_ideas
          link_plans
        end
      end

      private

      def ideas
        @ideas ||= project.sibling_scope(:ideas).where(id: form.idea_ids)
      end

      def link_ideas
        project.link_resources(ideas, "included_ideas")
      end

      def plans
        @plans ||= project.sibling_scope(:plans).where(id: form.plan_ids)
      end

      def link_plans
        project.link_resources(plans, "included_plans")
      end
    end
  end
end
