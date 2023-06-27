# frozen_string_literal: true

module Decidim
  module Budgets
    # This class deals with uploading help section images in participatory
    # budgeting.
    class HelpSectionImageUploader < Decidim::RecordImageUploader
      set_variants do
        {
          default: { resize_to_limit: [2000, 830] },
          small: { resize_to_fill: [1100, 460] }
        }
      end
    end
  end
end
