# frozen_string_literal: true

class AddMainImageToProjects < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_budgets_projects, :main_image, :string
  end
end
