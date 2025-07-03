# frozen_string_literal: true

module Decidim
  module Budgets
    # This class deals with uploading images to budgets.
    class BudgetImageUploader < Decidim::ImageUploader
      def content_type_allowlist
        %w(image/jpeg image/png image/svg+xml)
      end

      def extension_allowlist
        %w(jpeg jpg png svg)
      end
    end
  end
end
