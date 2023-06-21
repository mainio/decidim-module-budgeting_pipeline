# frozen_string_literal: true

require "spec_helper"

describe "Explore projects", type: :system do
  include_context "with budgeting setup"

  describe "index" do
    it "lists the first page of projects" do
      visit_component

      expect(page).to have_content("FOUND 50 PROPOSALS")
    end

    context "when filtering" do
      before do
        visit_component
        page.scroll_to find("form.new_filter")
      end

      it "can filter based on keywords" do
        within "form.new_filter" do
          find(%(input[aria-label="Keyword"])).set(translated(budget1_projects.first.title))
          click_button "Search"
        end

        expect(page).to have_content("FOUND 1 PROPOSAL")
      end

      it "can filter based on the area" do
        within "form.new_filter" do
          find(%(select[aria-label="Area"])).find(%(option[value="#{budget1.id}"])).select_option
          click_button "Search"
        end

        expect(page).to have_content("FOUND 10 PROPOSALS")
      end

      it "can filter based on the budget" do
        within "form.new_filter" do
          click_button "Show more search criteria"
          scroll_to find("#additional_search")

          find(%(input[aria-label="Minimum budget"])).set(16_000)
          find(%(input[aria-label="Maximum budget"])).set(20_000)
          click_button "Search"
        end

        expect(page).to have_content("FOUND 20 PROPOSALS")
      end
    end
  end

  describe "show" do
    let(:project) { budget1_projects.first }

    before do
      visit_project(project)
    end

    it "shows the project details" do
      scroll_to find(".resource-details")

      expect(page).to have_content("##{project.id}")
      expect(page).to have_content(translated(project.budget.title))
      expect(page).to have_content(project.address)
      expect(page).to have_content(translated(project.title))
      expect(page).to have_content(strip_tags(translated(project.description)))
    end

    context "when the project has a category with a parent category" do
      let(:category) { create(:category, participatory_space: component.participatory_space, parent: parent_category) }
      let(:parent_category) { create(:category, participatory_space: component.participatory_space) }

      let!(:project) { create(:budgeting_pipeline_project, budget: budget1, category: category) }

      it "displays the category and its parent category" do
        scroll_to find(".resource-details")

        expect(page).to have_content(translated(parent_category.name))
        expect(page).to have_content(translated(category.name))
      end
    end
  end
end
