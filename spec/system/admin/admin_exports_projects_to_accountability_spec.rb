# frozen_string_literal: true

require "spec_helper"

describe "AdminExportsProjectsToAccountability" do
  let(:manifest_name) { "budgets" }
  let(:budget) { create(:budgeting_pipeline_budget, component: current_component) }
  let!(:selected_projects) { create_list(:budgeting_pipeline_project, 5, budget:, selected_at: Time.current) }
  let!(:other_projects) { create_list(:budgeting_pipeline_project, 10, budget:) }

  let!(:accountability_component) { create(:accountability_component, participatory_space: current_component.participatory_space) }

  include_context "when managing a component as an admin"

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
    visit_component_admin
    click_on "Exports proposals to results"
  end

  it "can export projects to accountability" do
    select translated(accountability_component.name), from: :accountability_export_target_component_id
    check :accountability_export_export_all_selected_projects

    expect { click_on "Export to results" }.to change(Decidim::Accountability::Result, :count).by(selected_projects.count)

    expect(page).to have_content("Proposals successfully exported to results")
  end

  context "when some selected projects are soft deleted" do
    before do
      selected_projects.first(2).each(&:destroy!)
    end

    it "only exports non-deleted selected projects" do
      select translated(accountability_component.name), from: :accountability_export_target_component_id
      check :accountability_export_export_all_selected_projects

      expect { click_on "Export to results" }.to change(Decidim::Accountability::Result, :count).by(selected_projects.count - 2)

      expect(page).to have_content("Proposals successfully exported to results")
    end
  end

  context "when checking the exported details" do
    let!(:selected_projects) { create_list(:budgeting_pipeline_project, 1, budget:, selected_at: Time.current) }
    let(:project) { selected_projects.first }

    let(:result) { Decidim::Accountability::Result.order(:id).last }

    it "they match with the original projects" do
      perform_export

      expect(result.component).to eq(accountability_component)
      expect(translated(result.title)).to eq(decidim_sanitize(translated(project.title)))
      expect(result.description).to eq(project.description)
      expect(result.progress).to eq(0)
      expect(result.status).to be_nil
      expect(result.weight).to eq(0)
    end

    context "with statuses" do
      let!(:status_one) { create(:status, component: accountability_component, progress: 10) }
      let!(:status_two) { create(:status, component: accountability_component, progress: 50) }

      it "sets the correct status for the result" do
        perform_export

        expect(result.progress).to eq(10)
        expect(result.status).to eq(status_one)
      end
    end

    context "with taxonomies" do
      let(:root_taxonomy) { create(:taxonomy, organization: current_component.organization, name: { "en" => "Root taxonomy" }) }
      let(:taxonomy) { create(:taxonomy, parent: root_taxonomy, organization: current_component.organization, name: { "en" => "Test taxonomy" }) }
      let!(:selected_projects) { create_list(:budgeting_pipeline_project, 1, budget:, selected_at: Time.current) }
      let(:project) { selected_projects.first }

      before do
        create(:taxonomization, taxonomy: taxonomy, taxonomizable: project)
      end

      it "sets the correct taxonomies" do
        perform_export

        expect(result.taxonomies).to include(taxonomy)
        expect(result.taxonomies).not_to include(root_taxonomy)
      end
    end

    context "when a selected project is soft deleted" do
      before do
        selected_projects.first.destroy!
      end

      it "does not export the soft deleted project" do
        expect { perform_export }.not_to change(Decidim::Accountability::Result, :count)
      end
    end

    def perform_export
      select translated(accountability_component.name), from: :accountability_export_target_component_id
      check :accountability_export_export_all_selected_projects
      click_on "Export to results"
    end
  end
end
