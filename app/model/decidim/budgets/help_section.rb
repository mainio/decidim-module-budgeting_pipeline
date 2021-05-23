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

      validates_upload :image
      mount_uploader :image, Decidim::Budgets::HelpSectionImageUploader
    end
  end
end
