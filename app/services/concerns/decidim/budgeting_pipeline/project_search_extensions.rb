# frozen_string_literal: true

# Adds the extra fields to the admin categories form.
module Decidim
  module BudgetingPipeline
    module ProjectSearchExtensions
      extend ActiveSupport::Concern

      included do
        def initialize(options = {})
          super(Decidim::Budgets::Project.all, options)

          @budgets = options[:budgets]
        end

        def base_query
          raise "Missing component" unless component

          if @budgets
            @scope.where(decidim_budgets_budget_id: @budgets)
          else
            @scope.joins(:budget).where(
              decidim_budgets_budgets: { decidim_component_id: component.id }
            )
          end
        end

        # These are not is not automatically called and they are required to
        # make the parameter methods (e.g. `budget_id`) available through
        # Searchlight.
        method_added :search_budget_id
        method_added :search_budget_amount_min
        method_added :search_budget_amount_max
        method_added :search_status
        method_added :search_activity
      end

      # Handle the category_id filter
      def search_budget_id
        return query if budget_ids.blank?
        return query if budget_ids.include?("all")

        query.where(decidim_budgets_budget_id: budget_ids)
      end

      def search_budget_amount_min
        return query if budget_amount_min.blank?

        query.where("budget_amount >= ?", budget_amount_min)
      end

      def search_budget_amount_max
        return query if budget_amount_max.blank?

        query.where("budget_amount <= ?", budget_amount_max)
      end

      def search_status
        return query if status.blank?

        if status == "selected"
          query.where.not(selected_at: nil)
        else
          query.where(selected_at: nil)
        end
      end

      def search_activity
        case activity
        when "own"
          # TODO: Filter by related records that the user has coauthored.
          query
        when "favorites"
          query.user_favorites(@user)
        else # "all"
          query
        end
      end

      private

      # Private: Returns an array with checked category ids.
      def budget_ids
        Array(budget_id)
      end
    end
  end
end
