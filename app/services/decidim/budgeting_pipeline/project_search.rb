# frozen_string_literal: true

# Adds the extra fields to the admin categories form.
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

        search_text = params[:search_text_cont]
        if search_text && (id_match = search_text.match(/\A#([0-9]+)\z/))
          params.delete(:search_text_cont)
          params[:id_eq] = id_match[1]
        end

        super(params)
      end
    end
  end
end
