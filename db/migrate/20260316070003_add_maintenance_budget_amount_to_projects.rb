# frozen_string_literal: true

class AddMaintenanceBudgetAmountToProjects < ActiveRecord::Migration[6.1]
  def change
    add_column :decidim_budgets_projects, :maintenance_budget_amount, :integer, default: nil, null: true
  end
end
