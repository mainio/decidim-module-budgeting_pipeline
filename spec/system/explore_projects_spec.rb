# frozen_string_literal: true

require "spec_helper"

describe "ExploreProjects" do
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
          find(%(input[name="filter[search_text_cont]"])).set(translated(budget_one_projects.first.title))
          click_on "Search"
        end

        expect(page).to have_content("Found 1 proposal")
      end

      it "can filter based on the area" do
        within "form.new_filter" do
          find(%(select[name="filter[decidim_budgets_budget_id_eq]"])).find(%(option[value="#{budget_one.id}"])).select_option
          click_on "Search"
        end

        expect(page).to have_content("Found 10 proposals")
      end

      it "can filter based on the budget" do
        within "form.new_filter" do
          click_on "Show more search criteria"
          scroll_to find_by_id("additional_search")
        end

        find_by_id("additional_search").find("input[name='filter[budget_amount_lteq]']").set(16_000)
        find_by_id("additional_search").find("input[name='filter[budget_amount_lteq]']").set(20_000)
        click_on "Search"
        expect(page).to have_content("Found 20 proposals")
      end
    end
  end

  describe "show" do
    let(:project) { budget_one_projects.first }

    before do
      visit_project(project)
    end

    it "shows the project details" do
      expect(page).to have_content(project.id.to_s)
      expect(page).to have_content(translated(project.budget.title))
      expect(page).to have_content(project.address)
      expect(page).to have_content(translated(project.title))
      expect(page).to have_content(strip_tags(translated(project.description)))
    end

    context "when the project has a taxonomy with a parent taxonomy" do
      let(:root_taxonomy) { create(:taxonomy, organization:, name: { "en" => "Root taxonomy" }) }
      let(:taxonomy) { create(:taxonomy, parent: root_taxonomy, organization:, name: { "en" => "Test taxonomy" }) }

      before do
        create(:taxonomization, taxonomy: taxonomy, taxonomizable: project)
        visit_project(project)
      end

      it "displays the taxonomy and its root taxonomy" do
        expect(page).to have_content(translated(root_taxonomy.name))
        expect(page).to have_content(translated(taxonomy.name))
      end
    end

    context "when voting finished" do
      before do
        component.step_settings = { component.participatory_space.active_step.id => { votes: "finished", show_votes: true, show_selected_status: true } }
        component.save
        budget_one_projects.first.update(selected_at: Time.current)
      end

      it "renders status selection" do
        visit_component
        select_element = find("select[name='filter[with_any_status]']")
        expect(select_element).to have_css("option", text: "Proceeds to implementation")
        expect(select_element).to have_css("option", text: "Will not proceed to implementation")
        find("select[name='filter[with_any_status]']").select("Proceeds to implementation")
        within "form.new_filter" do
          click_on "Search"
        end
        within "#project-#{project.id}-item" do
          expect(page).to have_css(".card__text--status", text: "Selected")
        end
      end
    end

    context "when taxonomies exist" do
      include_context "with budget taxonomy filter"

      it "shows the taxonomies" do
        visit_component
        select_element = find("select[name='filter[with_any_taxonomies[#{root_taxonomy.id}]]']")
        expect(select_element).to have_css("option", text: translated(taxonomy_filter_item.taxonomy_item.name))
        expect(select_element).to have_css("option", text: translated(other_taxonomy_filter_item.taxonomy_item.name))
        expect(select_element).to have_css("option", text: translated(another_taxonomy_filter_item.taxonomy_item.name))
      end
    end
  end
end
