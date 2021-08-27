# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    # Extends the project helper with needed functionality.
    module ProjectsHelperExtensions
      extend ActiveSupport::Concern

      include Decidim::BudgetingPipeline::TextUtilities

      def landing_page_content
        translated_attribute(current_settings.landing_page_content).presence ||
          translated_attribute(component_settings.landing_page_content)
      end

      def projects_data_for_map(geocoded_projects_data)
        geocoded_projects_data.map do |data|
          {
            id: data[0],
            title: data[1],
            body: truncate(data[2], length: 100),
            address: data[3],
            latitude: data[4],
            longitude: data[5],
            link: project_path(data[0])
          }
        end
      end

      def projects_map(geocoded_projects)
        map_options = { type: "projects", markers: geocoded_projects }
        map_center = component_settings.default_map_center_coordinates
        center_values = map_center.split(",").map(&:to_f) if map_center
        map_options[:center_coordinates] = center_values if center_values && center_values.length > 1

        dynamic_map_for(map_options) do
          yield
        end
      end

      def filter_budgets_values
        budgets.map { |b| [translated_attribute(b.title), b.id] }
      end

      def filter_budgets_label
        if budgets.count == 2
          t("budgets_values.all.two", scope: "decidim.budgets.projects.filters")
        else
          t("budgets_values.all.other", scope: "decidim.budgets.projects.filters")
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

      def filter_activity_values
        [
          [t("decidim.budgets.projects.filters.activity_values.all"), "all"],
          [t("decidim.budgets.projects.filters.activity_values.favorites"), "favorites"]
        ]
      end

      def display_budgets_filter?
        budgets.count > 1
      end

      def display_status_filter?
        voting_finished? && statuses_available?
      end

      def display_category_filter?
        current_component.categories.any?
      end

      def display_budget_amount_filters?
        max = Decidim::Budgets::Project.where(budget: budgets).maximum(:budget_amount)
        max && max.positive?
      end

      def category_image_path(category)
        return unless category
        return unless category.respond_to?(:category_image)

        if category.category_image.blank? || category.category_image.url.blank?
          category_image_path(category.parent) if category.parent
        else
          category.category_image.url
        end
      end

      def project_map_link(resource, options = {})
        map_utility_static = Decidim::Map.static(
          organization: current_organization
        )
        return "#" unless map_utility_static

        map_utility_static.link(
          latitude: resource.latitude,
          longitude: resource.longitude,
          options: options
        )
      end

      def share_image_url
        project_image&.url || organization_share_image_url
      end

      def project_image
        project.main_image
      end

      def organization_share_image_url
        Decidim::ContentBlock.published.find_by(
          organization: current_organization,
          scope_name: :homepage,
          manifest_name: :hero
        ).try(:images_container).try(:background_image).try(:url)
      end

      def display_cart_button?
        controller.is_a?(Decidim::Budgets::VotesController)
      end
    end
  end
end
