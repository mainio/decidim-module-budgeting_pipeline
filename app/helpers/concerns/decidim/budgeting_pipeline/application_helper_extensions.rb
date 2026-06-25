# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    # Extends the application helper with needed functionality.
    module ApplicationHelperExtensions
      extend ActiveSupport::Concern

      included do
        def filter_status_values
          [
            [t("decidim.budgets.projects.filters.status_values.selected"), "selected"],
            [t("decidim.budgets.projects.filters.status_values.not_selected"), "not_selected"]
          ]
        end
      end

      def filter_taxonomy_values(taxonomy_filter)
        taxonomy_filter.filter_items.map do |item|
          [decidim_escape_translated(item.taxonomy_item.name), item.taxonomy_item.id]
        end.sort_by(&:first)
      end
    end
  end
end
