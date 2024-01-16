# frozen_string_literal: true

# Adds the extra data to budgets.
module Decidim
  module BudgetingPipeline
    module AdminUpdateBudgetExtensions
      extend ActiveSupport::Concern

      include Decidim::AttachmentAttributesMethods

      included do
        def update_budget!
          attributes = {
            scope: form.scope,
            title: form.title,
            weight: form.weight,
            description: form.description,
            total_budget: form.total_budget,
            center_latitude: form.center_latitude,
            center_longitude: form.center_longitude
          }.merge(attachment_attributes(:list_image))

          Decidim.traceability.update!(
            budget,
            form.current_user,
            attributes,
            visibility: "all"
          )
        end
      end
    end
  end
end
