# frozen_string_literal: true

module Decidim
  module Budgets
    # This model is used to store a single "vote" in order to show the votes in
    # the user's personal action logs (timeline). The single "vote" can contain
    # multiple orders in multiple budgets within the same component but we only
    # want to display a single item in the action log.
    class Vote < ApplicationRecord
      include Decidim::HasComponent

      # Make it work with the privacy module by fetching the users from the entire collection.
      belongs_to :user, -> { respond_to?(:entire_collection) ? entire_collection : self }, class_name: "Decidim::User", foreign_key: "decidim_user_id"
      has_many :orders, class_name: "Decidim::Budgets::Order", foreign_key: "decidim_budgets_vote_id", dependent: :destroy
    end
  end
end
