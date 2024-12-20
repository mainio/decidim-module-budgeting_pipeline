# frozen_string_literal: true

require "cell/partial"

module Decidim
  module Budgets
    # This cell renders a project with its L-size card.
    class ProjectLCell < Decidim::Budgets::ProjectGCell
      def card_classes
        classes = super
        classes = classes.split unless classes.is_a?(Array)
        (classes + ["card--full"]).join(" ")
      end

      private

      def resource_image_variant
        :thumbnail_box
      end

      def category_image_variant
        :card_box
      end
    end
  end
end
