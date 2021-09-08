# frozen_string_literal: true

module Decidim
  module Budgets
    # This class deals with uploading help section images in participatory
    # budgeting.
    class HelpSectionImageUploader < Decidim::RecordImageUploader
      process resize_to_limit: [2000, 830]

      version :small do
        process resize_to_fill: [1100, 460]
      end
    end
  end
end
