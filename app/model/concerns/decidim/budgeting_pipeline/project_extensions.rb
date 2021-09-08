# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    # Extends the project class with some options.
    module ProjectExtensions
      extend ActiveSupport::Concern

      include Decidim::HasUploadValidations
      include Decidim::Favorites::Favoritable

      class_methods do
        def geocoded_data_for(component)
          locale = Arel::Nodes.build_quoted(I18n.locale.to_s).to_sql

          default_latitude = 0.0
          default_longitude = 0.0

          map_center = component.settings.default_map_center_coordinates
          center_coodrdinates = map_center.split(",").map(&:to_f) if map_center
          if center_coodrdinates && center_coodrdinates.length > 1
            default_latitude = center_coodrdinates[0]
            default_longitude = center_coodrdinates[1]
          end

          joins(:budget).pluck(
            :id,
            "decidim_budgets_projects.title->>#{locale}",
            "decidim_budgets_projects.summary->>#{locale}",
            "decidim_budgets_projects.description->>#{locale}",
            Arel.sql(
              <<~SQLCASE
                CASE
                  WHEN CHAR_LENGTH(decidim_budgets_projects.address::text) > 0 THEN decidim_budgets_projects.address
                  ELSE decidim_budgets_budgets.title->>#{locale}
                END
              SQLCASE
            ),
            Arel.sql(
              <<~SQLCASE
                CASE
                  WHEN decidim_budgets_projects.latitude IS NOT NULL THEN decidim_budgets_projects.latitude
                  WHEN decidim_budgets_budgets.center_latitude IS NOT NULL THEN decidim_budgets_budgets.center_latitude
                  ELSE #{default_latitude}
                END
              SQLCASE
            ),
            Arel.sql(
              <<~SQLCASE
                CASE
                  WHEN decidim_budgets_projects.longitude IS NOT NULL THEN decidim_budgets_projects.longitude
                  WHEN decidim_budgets_budgets.center_longitude IS NOT NULL THEN decidim_budgets_budgets.center_longitude
                  ELSE #{default_longitude}
                END
              SQLCASE
            )
          )
        end
      end

      included do
        geocoded_by :address

        validates_upload :main_image
        mount_uploader :main_image, Decidim::Budgets::ProjectImageUploader
      end
    end
  end
end
