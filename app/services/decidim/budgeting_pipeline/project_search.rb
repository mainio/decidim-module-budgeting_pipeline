# frozen_string_literal: true

# Adds the extra fields to the admin categories form.
module Decidim
  module BudgetingPipeline
    class ProjectSearch < ResourceSearch
      attr_reader :activity

      def build(params)
        @activity = params[:activity]

        if activity && user
          case activity
          when "own"
            # TODO: Filter by related records that the user has coauthored.
          when "favorites"
            add_scope(:user_favorites, user)
          end
        end

        super
      end
    end
  end
end
