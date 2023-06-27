# frozen_string_literal: true

module Decidim
  module Budgets
    # Help sections to help in the budgeting process.
    class HelpSection < ApplicationRecord
      include Decidim::Traceable
      include Decidim::Loggable
      include Decidim::HasUploadValidations
      include Decidim::TranslatableResource
      include Decidim::HasComponent

      translatable_fields :title, :description, :link_text

      validates_upload :image, uploader: Decidim::Budgets::HelpSectionImageUploader
      has_one_attached :image
    end
  end
end
