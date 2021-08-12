# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    module VoteUtilities
      extend ActiveSupport::Concern

      included do
        helper_method :user_voted?
      end

      private

      def user_voted?
        current_workflow.voted.any?
      end
    end
  end
end
