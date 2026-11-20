# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    # Customizes the project card cell
    module ProjectCellExtensions
      extend ActiveSupport::Concern

      include Decidim::BudgetingPipeline::ProjectItemUtilities
      include Decidim::BudgetingPipeline::LinkUtilities

      included do
        delegate(
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

      def card_wrapper
        cls = card_classes.is_a?(Array) ? card_classes.join(" ") : card_classes
        wrapper_options = { class: "card #{cls}", aria: { label: t(".card_label", title:) } }
        if has_link_to_resource? && !voting?
          link_to resource_path, **wrapper_options do
            yield
          end
        else
          aria_options = { role: "region" }
          content_tag :div, **aria_options, **wrapper_options do
            yield
          end
        end
      end

      def render_column?
        !context[:no_column].presence
      end

      def voting?
        options[:voting] == true
      end

      def show_favorite_button?
        !context[:disable_favorite].presence
      end

      def taxonomies
        @taxonomies ||= model.taxonomies
      end

      def has_taxonomies?
        taxonomies.any?
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
        voting_finished? && model.component.current_settings.show_selected_status?
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
        @statuses ||= [:comments_count, :favorites_count].tap do |details|
          details << :votes_count if votes_visible?
        end
      end

      def votes_count_status
        with_tooltip t("decidim.budgets.project_m.votes_count") do
          render :votes_counter
        end
      end

      def creation_date_status
        l(model.created_at.to_date, format: :decidim_short)
      end

      def favorites_count_status
        cell("decidim/favorites/favorites_count", model)
      end

      def comments_count_status
        render_comments_count
      end

      def taxonomy_icons
        return [] unless has_taxonomies?

        taxonomies.filter_map do |t|
          next unless t.respond_to?(:taxonomy_icon) && t.taxonomy_icon&.attached?

          {
            taxonomy: t,
            icon: content_tag(:span, class: "card__taxonomy__icon", "aria-hidden": true) do
              image_tag(t.attached_uploader(:taxonomy_icon).url, alt: translated_attribute(t.name))
            end
          }
        end
      end

      # Returns an array of style hashes for taxonomies that have a color defined.
      # Each hash contains :taxonomy (the taxonomy object) and :style (the inline CSS string).
      def taxonomy_styles
        return [] unless has_taxonomies?

        taxonomies.filter_map do |t|
          next unless t.respond_to?(:color) && t.color.present?

          { taxonomy: t, style: "background-color:#{t.color};" }
        end
      end

      def resource_image_path(_project)
        return model.attached_uploader(:main_image).variant_url(resource_image_variant) if has_image?
        return unless has_taxonomies?

        taxonomy_image_path
      end

      def resource_image_variant
        :thumbnail
      end

      # Returns an array of CSS class strings, one per taxonomy.
      def taxonomy_classes
        return [] unless has_taxonomies?

        taxonomies.map { |t| "card__taxonomy--#{t.id}" }
      end

      def description
        project_summary_for(model)
      end

      def taxonomy_image_path
        taxonomy = taxonomies.find { |t| t.respond_to?(:taxonomy_image) && t.taxonomy_image&.attached? }
        return unless taxonomy

        taxonomy.attached_uploader(:taxonomy_image).variant_url(taxonomy_image_variant)
      end

      def taxonomy_image_variant
        :card
      end
    end
  end
end
