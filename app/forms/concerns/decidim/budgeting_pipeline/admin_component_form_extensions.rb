# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    # Modify the budgets component form.
    module AdminComponentFormExtensions
      extend ActiveSupport::Concern

      included do
        private

        def budget_voting_rule_minimum_value_setting
          return unless manifest&.name == :budgets
          return unless settings.vote_rule_minimum_budget_projects_enabled

          invalid_minimum_number = settings.vote_minimum_budget_projects_number.blank? || settings.vote_minimum_budget_projects_number.negative?
          settings.errors.add(:vote_minimum_budget_projects_number) if invalid_minimum_number
        end
      end
    end
  end
end
