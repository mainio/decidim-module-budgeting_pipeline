# frozen_string_literal: true

# Adds the error reasons for the invalid event.
module Decidim
  module BudgetingPipeline
    module AddLineItemExtensions
      extend ActiveSupport::Concern

      included do
        def call
          invalid_reason =
            if voting_not_enabled?
              :voting_not_enabled
            elsif order.checked_out?
              :order_checked_out
            elsif !order.allocation_available_for?(project)
              if order.projects_rule?
                :project_exceeds_amount
              else
                :project_exceeds_budget
              end
            end
          return broadcast(:invalid, invalid_reason) if invalid_reason

          transaction do
            add_line_item
            broadcast(:ok, order)
          end
        end
      end
    end
  end
end
