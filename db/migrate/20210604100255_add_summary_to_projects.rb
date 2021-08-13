# frozen_string_literal: true

class AddSummaryToProjects < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_budgets_projects, :summary, :jsonb
  end
end
