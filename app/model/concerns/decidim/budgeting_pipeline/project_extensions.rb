# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    # Extends the project class with some options.
    module ProjectExtensions
      extend ActiveSupport::Concern

      include Decidim::HasUploadValidations
      include Decidim::Favorites::Favoritable
      include Decidim::Stats::Measurable

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
            Arel.sql("CASE #{locale_case("decidim_budgets_projects.title")} END AS geotitle"),
            Arel.sql("CASE #{locale_case("decidim_budgets_projects.summary")} END AS geosummary"),
            Arel.sql("CASE #{locale_case("decidim_budgets_projects.description")} END AS geodescription"),
            Arel.sql(
              <<~SQLCASE.squish
                CASE
                  WHEN CHAR_LENGTH(decidim_budgets_projects.address::text) > 0 THEN decidim_budgets_projects.address
                  #{locale_case("decidim_budgets_budgets.title")}
                END AS geoaddress
              SQLCASE
            ),
            Arel.sql(
              <<~SQLCASE.squish
                CASE
                  WHEN decidim_budgets_projects.latitude IS NOT NULL THEN decidim_budgets_projects.latitude
                  WHEN decidim_budgets_budgets.center_latitude IS NOT NULL THEN decidim_budgets_budgets.center_latitude
                  ELSE #{default_latitude}
                END AS geolatitude
              SQLCASE
            ),
            Arel.sql(
              <<~SQLCASE.squish
                CASE
                  WHEN decidim_budgets_projects.longitude IS NOT NULL THEN decidim_budgets_projects.longitude
                  WHEN decidim_budgets_budgets.center_longitude IS NOT NULL THEN decidim_budgets_budgets.center_longitude
                  ELSE #{default_longitude}
                END AS geolongitude
              SQLCASE
            )
          )
        end

        def locale_case(column)
          locale = Arel::Nodes.build_quoted(I18n.locale.to_s).to_sql
          default_locale = Arel::Nodes.build_quoted(I18n.default_locale.to_s).to_sql

          return "WHEN true THEN #{column}->>#{locale}" if locale == default_locale

          <<~SQLCASE.squish
            WHEN CHAR_LENGTH((#{column}->>#{locale})::text) > 0 THEN #{column}->>#{locale}
            ELSE #{column}->>#{default_locale}
          SQLCASE
        end
      end

      included do
        geocoded_by :address

        validates_upload :main_image, uploader: Decidim::Budgets::ProjectImageUploader
        has_one_attached :main_image

        scope :order_by_most_voted, lambda { |only_voted: false|
          scope = joins(
            <<~SQLJOIN.squish
              LEFT JOIN decidim_budgets_line_items
                ON decidim_budgets_line_items.decidim_project_id = decidim_budgets_projects.id
            SQLJOIN
          ).joins(
            <<~SQLJOIN.squish
              LEFT JOIN decidim_budgets_orders
                ON decidim_budgets_orders.id = decidim_budgets_line_items.decidim_order_id
                AND decidim_budgets_orders.checked_out_at IS NOT NULL
            SQLJOIN
          ).select(
            [
              "decidim_budgets_projects.*",
              "COUNT(decidim_budgets_orders.id) + decidim_budgets_projects.paper_orders_count AS votes_count",
              "CASE #{Arel.sql locale_case("decidim_budgets_projects.title")} END AS localized_title"
            ].join(", ")
          ).group("decidim_budgets_projects.id")

          if only_voted
            voted_ids = joins(
              Arel.sql("LEFT JOIN (#{scope.to_sql}) AS with_votes ON with_votes.id = decidim_budgets_projects.id")
            ).where("with_votes.votes_count > 0").pluck(:id)
            scope = scope.where(id: voted_ids)
          end

          scope.order(
            votes_count: :desc,
            localized_title: :asc
          )
        }

        # Public: Returns the number of times an specific project have been checked out.
        def confirmed_orders_count
          orders.finished.count + paper_orders_count
        end

        def self.ransack(params = {}, options = {})
          ProjectSearch.new(self, params, options)
        end
      end
    end
  end
end
