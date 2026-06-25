# frozen_string_literal: true

# Adds the extra data to budgets.
module Decidim
  module BudgetingPipeline
    module AdminUpdateProjectExtensions
      extend ActiveSupport::Concern

      include Decidim::AttachmentAttributesMethods

      included do
        fetch_form_attributes :taxonomizations, :title, :description, :budget_amount, :address, :latitude, :longitude, :summary, :budget_amount_min

        def run_after_hooks
          link_proposals
          create_gallery if process_gallery?
          photo_cleanup!

          link_ideas
          link_plans
        end

        # The attached image gets cleared out for some reason during the record
        # reload, so we update the attachment attributes after the photo
        # cleanup instead of updating them directly during the record update.
        def photo_cleanup!
          super

          resource.update!(attachment_attributes(:main_image))
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
