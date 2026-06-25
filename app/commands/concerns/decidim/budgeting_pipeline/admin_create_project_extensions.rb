# frozen_string_literal: true

# Adds the extra data to projects.
module Decidim
  module BudgetingPipeline
    module AdminCreateProjectExtensions
      extend ActiveSupport::Concern

      include Decidim::AttachmentAttributesMethods

      included do
        fetch_form_attributes :budget, :taxonomizations, :title, :description, :budget_amount, :address, :latitude, :longitude, :summary, :budget_amount_min

        def run_after_hooks
          @attached_to = resource
          link_proposals
          create_gallery if process_gallery?

          link_ideas
          link_plans
        end

        def attributes
          super.merge(
            attachment_attributes(:main_image)
          )
        end
      end

      private

      def ideas
        @ideas ||= resource.sibling_scope(:ideas).where(id: form.idea_ids)
      end

      def link_ideas
        resource.link_resources(ideas, "included_ideas")
      end

      def plans
        @plans ||= resource.sibling_scope(:plans).where(id: form.plan_ids)
      end

      def link_plans
        resource.link_resources(plans, "included_plans")
      end
    end
  end
end
