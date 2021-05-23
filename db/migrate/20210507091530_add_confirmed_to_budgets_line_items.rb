# frozen_string_literal: true

class AddConfirmedToBudgetsLineItems < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_budgets_line_items, :confirmed, :boolean, null: false, default: false
  end
end
