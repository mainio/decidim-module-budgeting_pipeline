# frozen_string_literal: true

class AddMinBudgetAmountToProject < ActiveRecord::Migration[6.1]
  def change
    add_column :decidim_budgets_projects, :budget_amount_min, :integer, default: nil, null: true
  end
end
