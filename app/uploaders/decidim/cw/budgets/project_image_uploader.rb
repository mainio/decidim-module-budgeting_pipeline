# frozen_string_literal: true

module Decidim::Cw
  module Budgets
    # This class deals with uploading images to projects.
    class ProjectImageUploader < Decidim::Cw::RecordImageUploader
      process :orientate

      version :thumbnail do
        process resize_to_fill: [860, 340]
      end

      version :big do
        process resize_to_limit: [nil, 1000]
      end

      version :main do
        process resize_to_fill: [1480, 740]
      end

      def max_image_height_or_width
        8000
      end

      protected

      # Flips the image to be in correct orientation based on its Exif
      # orientation metadata.
      def orientate
        manipulate! do |img|
          img.tap(&:auto_orient)
          img = yield(img) if block_given?
          img
        end
      end
    end
  end
end
