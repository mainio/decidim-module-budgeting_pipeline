# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    # Extends the line item class with some options.
    module LineItemExtensions
      extend ActiveSupport::Concern

      class_methods do
        def order_by_projects
          joins(:project).order("decidim_budgets_projects.title->>'#{Arel.sql(I18n.locale.to_s)}'")
        end
      end
    end
  end
end
