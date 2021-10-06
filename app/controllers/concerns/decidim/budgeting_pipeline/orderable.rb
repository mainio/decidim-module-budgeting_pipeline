# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    # Adds the orders methods to the controllers that list projects.
    module Orderable
      extend ActiveSupport::Concern

      included do
        private

        # Available orders based on enabled settings
        def available_orders
          @available_orders ||= begin
            available_orders = []
            if votes_are_visible?
              available_orders +=
                if voting_open?
                  %w(random)
                else
                  %w(most_voted random)
                end
            else
              available_orders << "random"
            end
            available_orders += %w(alphabetical highest_cost lowest_cost)
            available_orders
          end
        end

        def reorder(projects)
          case order
          when "highest_cost"
            projects.order(budget_amount: :desc)
          when "lowest_cost"
            projects.order(budget_amount: :asc)
          when "most_voted"
            if votes_are_visible? && !voting_open?
              projects.order_by_most_voted
            else
              projects
            end
          when "alphabetical"
            projects.order("title->>'#{Arel.sql(current_locale)}'")
          when "random"
            projects.order_randomly(random_seed)
          else
            projects
          end
        end
      end
    end
  end
end
