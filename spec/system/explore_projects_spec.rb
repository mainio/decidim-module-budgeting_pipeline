# frozen_string_literal: true

require "spec_helper"

describe "Explore projects", type: :system do
  include_context "with budgeting setup"

  describe "index" do
    it "lists the first page of projects" do
      visit_component

      expect(page).to have_content("Found 50 proposals")
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

        expect(page).to have_content("Found 1 proposal")
      end

      it "can filter based on the area" do
        within "form.new_filter" do
          find(%(select[aria-label="Area"])).find(%(option[value="#{budget1.id}"])).select_option
          click_button "Search"
        end

        expect(page).to have_content("Found 10 proposals")
      end

      it "can filter based on the budget" do
        within "form.new_filter" do
          click_button "Show more search criteria"
          scroll_to find("#additional_search")

          find(%(input[aria-label="Minimum budget"])).set(16_000)
          find(%(input[aria-label="Maximum budget"])).set(20_000)
          click_button "Search"
        end

        expect(page).to have_content("Found 20 proposals")
      end
    end
  end

  describe "show" do
    let(:project) { budget1_projects.first }

    before do
      visit_project(project)
    end

    it "shows the project details" do
      scroll_to find(".resource__details")

      expect(page).to have_content("##{project.id}")
      expect(page).to have_content(decidim_sanitize(translated(project.budget.title)))
      expect(page).to have_content(project.address)
      expect(page).to have_content(translated(project.title))
      expect(page).to have_content(strip_tags(translated(project.description)))
    end

    context "when the project has a category with a parent category" do
      let(:category) { create(:category, participatory_space: component.participatory_space, parent: parent_category) }
      let(:parent_category) { create(:category, participatory_space: component.participatory_space) }

      let!(:project) { create(:budgeting_pipeline_project, budget: budget1, category: category) }

      it "displays the category and its parent category" do
        scroll_to find(".resource__details")

        expect(page).to have_content(translated(parent_category.name))
        expect(page).to have_content(translated(category.name))
      end
    end

    context "when voting finished" do
      before do
        component.step_settings = { component.participatory_space.active_step.id => { votes: "finished", show_votes: true } }
        component.save
        budget1_projects.first.update(selected_at: Time.current)
      end

      it "renders status selection" do
        visit_component
        select_element = find("select[name='filter[with_any_status]']")
        expect(select_element).to have_selector("option", text: "Proceeds to implementation")
        expect(select_element).to have_selector("option", text: "Will not proceed to implementation")
        find("select[name='filter[with_any_status]']").select("Proceeds to implementation")
        within "form.new_filter" do
          click_button "Search"
        end
        within "#project_#{project.id}" do
          expect(page).to have_content("Proceeds to implementation")
        end
      end
    end

    context "when categories exist" do
      let!(:categories) { create_list(:category, 2, participatory_space: component.participatory_space) }

      it "shows the categories" do
        visit_component
        select_element = find("select[name='filter[with_any_category]']")
        expect(select_element).to have_selector("option", text: translated(categories.first.name))
        expect(select_element).to have_selector("option", text: translated(categories.last.name))
      end
    end
  end
end
