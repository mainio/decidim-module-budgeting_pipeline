# frozen_string_literal: true

class AddPaperOrdersCountToProjects < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_budgets_projects, :paper_orders_count, :integer, null: false, default: 0
  end
end
