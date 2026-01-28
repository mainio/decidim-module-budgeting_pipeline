# frozen_string_literal: true

class AddAnswerToProjects < ActiveRecord::Migration[6.1]
  def change
    add_column :decidim_budgets_projects, :answer, :jsonb
  end
end
