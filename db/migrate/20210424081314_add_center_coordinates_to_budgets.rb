# frozen_string_literal: true

class AddCenterCoordinatesToBudgets < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_budgets_budgets, :center_latitude, :float
    add_column :decidim_budgets_budgets, :center_longitude, :float
  end
end
