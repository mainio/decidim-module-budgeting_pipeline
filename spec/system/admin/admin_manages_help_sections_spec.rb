# frozen_string_literal: true

require "spec_helper"

describe "Admin manages help sections", type: :system do
  let(:manifest_name) { "budgets" }
  let!(:index_sections) { create_list(:budgeting_pipeline_help_section, 2, component: current_component, key: :index) }
  let!(:pipeline_sections) { create_list(:budgeting_pipeline_help_section, 2, component: current_component, key: :pipeline) }

  include_context "when managing a component as an admin"

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
    visit_component_admin
    click_link "Helping content"
  end

  describe "index" do
    it "lists available help containers" do
      within ".table-list" do
        expect(page).to have_link("Front page")
        expect(page).to have_link("Voting pipeline")
      end
    end

    it "browsing through the help sections" do
      within ".table-list" do
        click_link "Front page"
      end

      within "h1.item_show__header-title" do
        expect(page).to have_content("Front page")
      end

      within ".table-list" do
        index_sections.each do |section|
          expect(page).to have_content(translated(section.title))
        end
      end

      within "h1.item_show__header-title" do
        click_link "Helping content"
      end

      within ".table-list" do
        click_link "Voting pipeline"
      end

      within ".table-list" do
        pipeline_sections.each do |section|
          expect(page).to have_content(translated(section.title))
        end
      end
    end
  end

  describe "create" do
    before do
      within ".table-list" do
        click_link "Front page"
      end

      click_on "New help section"
      expect(page).to have_content("New help section")
    end

    it "allows creating a new help section" do
      fill_in_details
      click_on "Create help section"

      expect(page).to have_content("Help section successfully created")
      within ".table-list" do
        expect(page).to have_content("My new title")
      end

      expect_details_for(Decidim::Budgets::HelpSection.order(:id).last)
    end
  end

  describe "update" do
    let(:section) { index_sections[0] }

    before do
      within ".table-list" do
        click_link "Front page"
      end

      within ".table-list" do
        click_link translated(section.title)
      end
    end

    it "allows updating the help section" do
      fill_in_details
      click_button "Update help section"

      expect(page).to have_content("Help section successfully updated")
      within ".table-list" do
        expect(page).to have_content("My new title")
      end

      expect_details_for(section.reload)
    end
  end

  describe "destroy" do
    let(:section) { index_sections[0] }

    before do
      within ".table-list" do
        click_link "Front page"
      end

      within "h1.item_show__header-title" do
        expect(page).to have_content("Front page")
      end
    end

    it "allows destroying the help section" do
      expect do
        within ".table-list" do
          within "tr[data-id='#{section.id}']" do
            accept_confirm { click_link "Delete" }
          end
        end
      end.to change(Decidim::Budgets::HelpSection, :count).by(-1)
    end
  end

  def fill_in_details
    fill_in_i18n(
      :help_section_title,
      "#help_section-title-tabs",
      en: "My new title",
      es: "Mi nuevo título",
      ca: "El meu nou títol"
    )
    fill_in :help_section_weight, with: 123
    fill_in_i18n_editor(
      :help_section_description,
      "#help_section-description-tabs",
      en: "A longer description",
      es: "Descripción más larga",
      ca: "Descripció més llarga"
    )
    fill_in_i18n(
      :help_section_link_text,
      "#help_section-link_text-tabs",
      en: "New link text",
      es: "Nuevo texto para enlace",
      ca: "Nou text per a l'enllaç"
    )
    fill_in :help_section_link, with: "https://example.org"
  end

  def expect_details_for(section)
    expect(section.title.reject { |k| k == "machine_translations" }).to eq(
      "en" => "My new title",
      "es" => "Mi nuevo título",
      "ca" => "El meu nou títol"
    )
    expect(section.weight).to eq(123)
    expect(section.description.reject { |k| k == "machine_translations" }).to eq(
      "en" => "<p>A longer description</p>",
      "es" => "<p>Descripción más larga</p>",
      "ca" => "<p>Descripció més llarga</p>"
    )
    expect(section.link_text.reject { |k| k == "machine_translations" }).to eq(
      "en" => "New link text",
      "es" => "Nuevo texto para enlace",
      "ca" => "Nou text per a l'enllaç"
    )
    expect(section.link).to eq("https://example.org")
  end
end
