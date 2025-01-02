# frozen_string_literal: true

require "cell/partial"

module Decidim
  module Budgets
    # This cell renders a project with its L-size card.
    class ProjectLCell < Decidim::Budgets::ProjectCell
      def card_classes
        ["card--full"]
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
