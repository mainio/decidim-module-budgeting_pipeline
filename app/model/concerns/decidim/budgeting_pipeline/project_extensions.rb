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
            "CASE #{locale_case("decidim_budgets_projects.title")} END AS geotitle",
            "CASE #{locale_case("decidim_budgets_projects.summary")} END AS geosummary",
            "CASE #{locale_case("decidim_budgets_projects.description")} END AS geodescription",
            Arel.sql(
              <<~SQLCASE
                CASE
                  WHEN CHAR_LENGTH(decidim_budgets_projects.address::text) > 0 THEN decidim_budgets_projects.address
                  #{locale_case("decidim_budgets_budgets.title")}
                END AS geoaddress
              SQLCASE
            ),
            Arel.sql(
              <<~SQLCASE
                CASE
                  WHEN decidim_budgets_projects.latitude IS NOT NULL THEN decidim_budgets_projects.latitude
                  WHEN decidim_budgets_budgets.center_latitude IS NOT NULL THEN decidim_budgets_budgets.center_latitude
                  ELSE #{default_latitude}
                END AS geolatitude
              SQLCASE
            ),
            Arel.sql(
              <<~SQLCASE
                CASE
                  WHEN decidim_budgets_projects.longitude IS NOT NULL THEN decidim_budgets_projects.longitude
                  WHEN decidim_budgets_budgets.center_longitude IS NOT NULL THEN decidim_budgets_budgets.center_longitude
                  ELSE #{default_longitude}
                END AS geolongitude
              SQLCASE
            )
          )
        end

        private

        def locale_case(column)
          locale = Arel::Nodes.build_quoted(I18n.locale.to_s).to_sql
          default_locale = Arel::Nodes.build_quoted(I18n.default_locale.to_s).to_sql

          return "WHEN true THEN #{column}->>#{locale}" if locale == default_locale

          <<~SQLCASE
            WHEN CHAR_LENGTH((#{column}->>#{locale})::text) > 0 THEN #{column}->>#{locale}
            ELSE #{column}->>#{default_locale}
          SQLCASE
        end
      end

      included do
        geocoded_by :address

        validates_upload :main_image
        mount_uploader :main_image, Decidim::Budgets::ProjectImageUploader

        scope :order_by_most_voted, lambda { |only_voted: false|
          join_type = only_voted ? "INNER" : "LEFT"
          joins(
            <<~SQLJOIN.squish
              #{Arel.sql(join_type)} JOIN decidim_budgets_line_items
                ON decidim_budgets_line_items.decidim_project_id = decidim_budgets_projects.id
            SQLJOIN
          ).joins(
            <<~SQLJOIN.squish
              #{Arel.sql(join_type)} JOIN decidim_budgets_orders
                ON decidim_budgets_orders.id = decidim_budgets_line_items.decidim_order_id
                AND decidim_budgets_orders.checked_out_at IS NOT NULL
            SQLJOIN
          ).select(
            [
              "decidim_budgets_projects.*",
              "COUNT(decidim_budgets_orders.id) AS votes_count",
              "CASE #{locale_case("decidim_budgets_projects.title")} END AS localized_title"
            ].join(", ")
          ).group("decidim_budgets_projects.id").order(
            votes_count: :desc,
            localized_title: :asc
          )
        }
      end
    end
  end
end
