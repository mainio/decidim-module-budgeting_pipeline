# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    # Customizes the project card cell
    module ProjectMCellExtensions
      extend ActiveSupport::Concern

      include Decidim::BudgetingPipeline::ProjectItemUtilities
      include Decidim::BudgetingPipeline::LinkUtilities

      included do
        delegate(
          :statuses_available?,
          :budget_order_line_item_path,
          :current_workflow,
          :allowed_to?,
          :current_component,
          to: :controller
        )

        def resource_path
          resource_locator([model.budget, model]).path + request_params_query(resource_utm_params)
        end
      end

      private

      def render_column?
        !context[:no_column].presence
      end

      def voting?
        options[:voting] == true
      end

      def show_favorite_button?
        !context[:disable_favorite].presence
      end

      def has_category?
        model.category.present?
      end

      def has_image?
        model.main_image && model.main_image.attached?
      end

      def has_badge?
        state_visible?
      end

      def voting_open?
        model.component.current_settings.votes == "enabled"
      end

      def voting_finished?
        model.component.current_settings.votes == "finished"
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

      def votes_visible?
        voting_finished? && model.component.current_settings.show_votes?
      end

      def votes_count
        model.confirmed_orders_count
      end

      def resource_utm_params
        return {} unless context[:utm_params]

        context[:utm_params].transform_keys do |key|
          "utm_#{key}"
        end
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

      def card_classes
        classes = super
        classes = classes.join(" ") if classes.is_a?(Array)
        return classes unless voted_for?(model)

        "#{classes} selected"
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
        raise full_category.inspect

        content_tag(:span, class: "card__category__icon", "aria-hidden": true) do
          image_tag(cat.attached_uploader(:category_icon).path, alt: full_category.join(" - "))
        end
      end

      def category_style
        cat = color_category
        return unless cat

        "background-color:#{cat.color};"
      end

      def resource_image_path
        return model.attached_uploader(:main_image).path(variant: :thumbnail) if has_image?

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
        return unless cat.category_image.attached?

        cat.attached_uploader(:category_image).path(variant: :card)
      end

      def icon_category(cat = nil)
        return unless has_category?

        cat ||= model.category
        return unless cat.respond_to?(:category_icon)
        return cat if cat.category_icon && cat.category_icon.attached?
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
