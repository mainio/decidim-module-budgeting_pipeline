# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    # Customizes the project card cell
    module ProjectMCellExtensions
      extend ActiveSupport::Concern

      include Decidim::BudgetingPipeline::ProjectItemUtilities

      included do
        delegate(
          :voting_finished?,
          :statuses_available?,
          :budget_order_line_item_path,
          :voting_open?,
          :current_workflow,
          :allowed_to?,
          :current_component,
          to: :controller
        )
      end

      private

      def render_column?
        !context[:no_column].presence
      end

      def voting?
        options[:voting] == true
      end

      def can_have_order?
        current_user.present? &&
          voting_open? &&
          allowed_to?(:create, :order, budget: model.budget, workflow: current_workflow)
      end

      def show_favorite_button?
        !context[:disable_favorite].presence
      end

      def has_category?
        model.category.present?
      end

      def has_image?
        model.main_image.present?
      end

      def has_badge?
        state_visible?
      end

      def state_visible?
        voting_done =
          if controller.is_a?(Decidim::HomepageController)
            model.component.current_settings.votes == "finished"
          else
            voting_finished?
          end

        voting_done && model.selected_at.present?
      end

      def resource_link(options = {})
        if voting?
          data = options[:data] || {}
          aria = options[:aria] || {}
          data[:remote] = true
          aria[:haspopup] = "dialog"
          options[:data] = data
          options[:aria] = aria
        end
        link_to resource_path, **options do
          yield
        end
      end

      def state_classes
        return ["success"] if model.selected_at.present?

        ["alert"]
      end

      def badge_name
        if model.selected_at.present?
          t("decidim.budgets.models.project.statuses.selected")
        else
          t("decidim.budgets.models.project.statuses.not_selected")
        end
      end

      def statuses
        [:creation_date, :favoriting_count, :comments_count]
      end

      def creation_date_status
        l(model.created_at.to_date, format: :decidim_short)
      end

      def favoriting_count_status
        cell("decidim/favorites/favoriting_count", model)
      end

      def category_icon
        cat = icon_category
        return unless cat

        full_category = []
        full_category << translated_attribute(cat.parent.name) if cat.parent
        full_category << translated_attribute(cat.name)

        content_tag(:span, class: "card__category__icon", "aria-hidden": true) do
          image_tag(cat.category_icon.url, alt: full_category.join(" - "))
        end
      end

      def category_style
        cat = color_category
        return unless cat

        "background-color:#{cat.color};"
      end

      def resource_image_path
        return model.main_image.thumbnail.url if has_image?

        path = category_image_path(model.category)
        return path if path

        category_image_path(model.category.parent) if model.category&.parent.present?
      end

      def category
        translated_attribute(model.category.name) if has_category?
      end

      def category_class
        "card__category--#{model.category.id}" if has_category?
      end

      def description
        project_summary_for(model)
      end

      def category_image_path(cat)
        return unless has_category?
        return unless cat.respond_to?(:category_image)
        return unless cat.category_image
        return cat.category_image.url unless cat.category_image.respond_to?(:card)

        cat.category_image.card.url
      end

      def icon_category(cat = nil)
        return unless has_category?

        cat ||= model.category
        return unless cat.respond_to?(:category_icon)
        return cat if cat.category_icon && cat.category_icon.url
        return unless cat.parent

        icon_category(cat.parent)
      end

      def color_category(cat = nil)
        return unless has_category?

        cat ||= model.category
        return unless cat.respond_to?(:color)
        return cat if cat.color
        return unless cat.parent

        color_category(cat.parent)
      end
    end
  end
end
