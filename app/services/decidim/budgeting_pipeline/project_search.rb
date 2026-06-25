# frozen_string_literal: true

# Extends the project search with additional filtering options.
module Decidim
  module BudgetingPipeline
    class ProjectSearch < ResourceSearch
      attr_reader :activity

      def build(params)
        @activity = params[:activity]

        if user
          add_scope(:user_favorites, user) if params[:favorites] == "1"
          add_scope(:voted_by, user) if params[:selected] == "1"
        end

        # In case the organization has been given, search with the linked plans
        if organization
          search_text = params.delete(:search_text_cont)
          add_scope(:matching_id_or_text_with_linked_plans, [search_text, organization.available_locales]) if search_text
        end

        if params[:with_any_taxonomies].is_a?(Hash)
          params[:with_any_taxonomies] = params[:with_any_taxonomies].transform_values do |v|
            Array(v).compact_blank
          end
        end

        super(params)
      end
    end
  end
end
