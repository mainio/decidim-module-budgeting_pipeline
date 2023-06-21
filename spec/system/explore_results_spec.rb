# frozen_string_literal: true

require "spec_helper"

describe "Explore results", type: :system do
  include ActionView::Helpers::NumberHelper

  include_context "with budgeting setup"

  describe "show" do
    it "lists the results in correct order" do
      visit_results

      all(".budget-results").each do |results|
        scroll_to results

        within results do
          title = find("h2")
          budget = find_budget_by_title(title.text)

          expect(page).to have_content(number_to_currency(budget.total_budget, unit: Decidim.currency_unit, precision: 0))

          if voted_budgets.include?(budget)
            click_button "Show more"

            projects = sorted_projects_for(budget)

            index = 0

            # Winning projects
            within all("table")[0] do
              all("tbody tr").each do |row|
                project = projects[index]

                within row do
                  cells = all("td")
                  expect(cells[0]).to have_content("#{index + 1}.")
                  expect(cells[1]).to have_content(translated(project.title))
                  expect(cells[2]).to have_content(number_to_currency(project.budget_amount, unit: Decidim.currency_unit, precision: 0))
                  expect(cells[3]).to have_content("#{project.confirmed_orders_count} pcs")
                end

                index += 1
              end
            end

            # Rest of projects
            within all("table")[1] do
              all("tbody tr").each do |row|
                project = projects[index]

                within row do
                  cells = all("td")
                  expect(cells[0]).to have_content("#{index + 1}.")
                  expect(cells[1]).to have_content(translated(project.title))
                  expect(cells[2]).to have_content(number_to_currency(project.budget_amount, unit: Decidim.currency_unit, precision: 0))
                  expect(cells[3]).to have_content("#{project.confirmed_orders_count} pcs")
                end

                index += 1
              end
            end
          else
            expect(page).to have_content("There are no votes in this area yet.")
          end
        end
      end
    end
  end

  def find_budget_by_title(title)
    budgets.each do |budget|
      return budget if translated(budget.title) == title
    end

    nil
  end

  def sorted_projects_for(budget)
    Decidim::Budgets::Project.where(budget: budget).order_by_most_voted(only_voted: false)
  end
end
