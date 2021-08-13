# frozen_string_literal: true

# Adds the extra data to budgets.
module Decidim
  module BudgetingPipeline
    module AdminUpdateProjectExtensions
      extend ActiveSupport::Concern

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
            }.merge(uploader_attributes)
          )
        end
      end

      private

      # Prevent the existing image to be re-processed.
      def uploader_attributes
        {
          main_image: form.main_image,
          remove_main_image: form.remove_main_image
        }.delete_if { |_k, val| val.is_a?(Decidim::ApplicationUploader) }
      end
    end
  end
end
