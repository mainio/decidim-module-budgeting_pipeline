# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    # Extends the line item class with some options.
    module LineItemExtensions
      extend ActiveSupport::Concern

      class_methods do
        def order_by_projects
          joins(:project).order(Arel.sql("decidim_budgets_projects.title->>'#{I18n.locale}'"))
        end
      end
    end
  end
end
