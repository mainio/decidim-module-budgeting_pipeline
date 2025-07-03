# frozen_string_literal: true

# Adds the extra data to budgets.
module Decidim
  module BudgetingPipeline
    module AdminCreateBudgetExtensions
      extend ActiveSupport::Concern

      include Decidim::AttachmentAttributesMethods

      included do
        def create_budget!
          attributes = {
            component: form.current_component,
            scope: form.scope,
            title: form.title,
            weight: form.weight,
            description: form.description,
            total_budget: form.total_budget,
            center_latitude: form.center_latitude,
            center_longitude: form.center_longitude
          }.merge(attachment_attributes(:list_image))

          @budget = Decidim.traceability.create!(
            Decidim::Budgets::Budget,
            form.current_user,
            attributes,
            visibility: "all"
          )
        end
      end
    end
  end
end
