# frozen_string_literal: true

module Decidim
  module Budgets
    # This model keeps track of cancelled votes for accountability reasons and
    # to keep the statistics in sync.
    class CancelledVote < ApplicationRecord
      include Decidim::HasComponent

      # Make it work with the privacy module by fetching the users from the entire collection.
      belongs_to :user, -> { respond_to?(:entire_collection) ? entire_collection : self }, class_name: "Decidim::User", foreign_key: "decidim_user_id"
      has_many :orders, class_name: "Decidim::Budgets::CancelledOrder", foreign_key: "decidim_budgets_cancelled_vote_id", dependent: :destroy

      def self.cancel_vote!(vote)
        create!(
          user: vote.user,
          component: vote.component,
          vote_cast_at: vote.created_at
        ).tap do |cancelled|
          vote.orders.each do |order|
            cancelled.cancel_order!(order)
          end

          # This will destroy all the related orders as well.
          vote.destroy!
        end
      end

      def cancel_order!(order)
        line_items_data = order.line_items.map(&:as_json)
        orders.create!(
          user: order.user,
          budget: order.budget,
          checked_out_at: order.checked_out_at,
          line_items_data: line_items_data
        )
      end
    end
  end
end
