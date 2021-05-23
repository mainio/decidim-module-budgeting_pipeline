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

      def filter_categories_values
        organization = current_component.participatory_space.organization

        sorted_main_categories = current_component.participatory_space.categories.first_class.includes(:subcategories).sort_by do |category|
          [category.weight, translated_attribute(category.name, organization)]
        end

        sorted_main_categories.map do |category|
          [translated_attribute(category.name, organization), category.id]
        end
      end
    end
  end
end
