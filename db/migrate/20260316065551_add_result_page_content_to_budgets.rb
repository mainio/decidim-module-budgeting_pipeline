# frozen_string_literal: true

class AddResultPageContentToBudgets < ActiveRecord::Migration[6.1]
  def change
    add_column :decidim_budgets_budgets, :result_page_content, :jsonb
  end
end
