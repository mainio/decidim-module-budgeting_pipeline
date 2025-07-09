# frozen_string_literal: true

module Decidim
  module Budgets
    # This model keeps track of cancelled orders for accountability reasons and
    # to keep the statistics in sync.
    class CancelledOrder < ApplicationRecord
      # Make it work with the privacy module by fetching the users from the entire collection.
      belongs_to :user, -> { respond_to?(:entire_collection) ? entire_collection : self }, class_name: "Decidim::User", foreign_key: "decidim_user_id"
      belongs_to :budget, foreign_key: "decidim_budgets_budget_id", class_name: "Decidim::Budgets::Budget"
      belongs_to :vote, class_name: "Decidim::Budgets::CancelledVote", foreign_key: "decidim_budgets_cancelled_vote_id"

      validates :checked_out_at, presence: true

      def line_items
        @line_items ||= line_items_data.map do |data|
          Decidim::Budgets::LineItem.new(data)
        end
      end

      def projects
        @projects ||= line_items.map(&:project)
      end
    end
  end
end
