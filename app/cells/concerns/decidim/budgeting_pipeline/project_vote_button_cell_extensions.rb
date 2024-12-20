# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    # Customizes the project list item cell
    module ProjectVoteButtonCellExtensions
      extend ActiveSupport::Concern

      private

      def resource_description
        translated_attribute model.description
      end

      def resource_description_teaser
        truncate(
          # Add a new line in-between the closing and opening tags for the text to
          # have spaces when the tags are removed. Otherwise the text would wrap as
          # the same long word.
          strip_tags(resource_description.gsub(%r{(</[^>]+>)(<[^>]+>)}, "\\1\n\\2")),
          length: 200
        )
      end
    end
  end
end
