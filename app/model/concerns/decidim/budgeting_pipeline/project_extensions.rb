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

        # Searches through the plan type linked resources in order for users
        # to discover budgeting projects or plans that match a specific text.
        #
        # Implemented as its own scope because the linked resource search is
        # difficult to implement in a performant way through ransack directly.
        scope :matching_id_or_text_with_linked_plans, lambda { |text, locales = []|
          id_match = text.match(/\A([0-9]+)\z/)

          query =
            if id_match
              where(id: text)
            else
              ransack(search_text_cont: text).result
            end
          return query if locales.empty?

          # Find with linked plans, this is the complex part as the plans
          # separate the content into different sections.
          plan_links = Decidim::ResourceLink.joins(
            "INNER JOIN decidim_budgets_projects ON decidim_budgets_projects.id = decidim_resource_links.from_id"
          ).where(
            from_type: name,
            to_type: "Decidim::Plans::Plan",
            decidim_budgets_projects: { id: self }
          ).distinct.pluck(:to_id)
          if plan_links.any?
            plan_components = Decidim::Plans::Plan.where(id: plan_links).distinct.pluck(:decidim_component_id)
            if plan_components.any?
              searchable_sections = Decidim::Plans::Section.where(component: plan_components, searchable: true)
              matching_plans =
                if id_match
                  Decidim::Plans::Plan.where(id: text)
                else
                  Decidim::Plans::Plan.containing_text(text, searchable_sections, locales)
                end
              query = query.or(
                where(
                  id: joins(:resource_links_from).joins(
                    "INNER JOIN decidim_plans_plans ON decidim_plans_plans.id = decidim_resource_links.to_id"
                  ).where(
                    decidim_resource_links: {
                      from_type: name,
                      to_type: "Decidim::Plans::Plan"
                    },
                    decidim_plans_plans: { id: matching_plans }
                  )
                )
              )
            end
          end

          query
        }

        scope :voted_by, lambda { |user|
          joins(:orders).where(decidim_budgets_orders: { decidim_user_id: user })
        }

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
