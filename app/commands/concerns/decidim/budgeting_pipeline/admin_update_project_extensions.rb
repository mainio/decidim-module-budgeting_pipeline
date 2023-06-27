# frozen_string_literal: true

# Adds the extra data to budgets.
module Decidim
  module BudgetingPipeline
    module AdminUpdateProjectExtensions
      extend ActiveSupport::Concern

      include Decidim::AttachmentAttributesMethods

      included do
        def update_project
          Decidim.traceability.update!(
            project,
            form.current_user,
            {
              scope: form.scope,
              category: form.category,
              title: form.title,
              summary: form.summary,
              description: form.description,
              budget_amount: form.budget_amount,
              selected_at: selected_at,
              address: form.address,
              latitude: form.latitude,
              longitude: form.longitude
            }
          )

          link_ideas
          link_plans
        end

        # The attached image gets cleared out for some reason during the record
        # reload, so we update the attachment attributes after the photo
        # cleanup instead of updating them directly during the record update.
        def photo_cleanup!
          super

          project.update!(attachment_attributes(:main_image))
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
