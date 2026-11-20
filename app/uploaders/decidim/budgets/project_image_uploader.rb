# frozen_string_literal: true

module Decidim
  module Budgets
    # This class deals with uploading images to projects.
    class ProjectImageUploader < Decidim::RecordImageUploader
      set_variants do
        {
          default: { auto_orient: true },
          thumbnail: { resize_to_fill: [860, 395], auto_orient: true },
          thumbnail_box: { resize_to_fill: [660, 450], auto_orient: true },
          big: { resize_to_limit: [nil, 1000], auto_orient: true },
          main: { resize_to_fill: [1500, 920], auto_orient: true }
        }
      end

      def max_image_height_or_width
        8000
      end
    end
  end
end
