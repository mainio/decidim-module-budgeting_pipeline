# frozen_string_literal: true

require "spec_helper"

describe "Admin exports projects to accountability", type: :system do
  let(:manifest_name) { "budgets" }
  let(:budget) { create(:budgeting_pipeline_budget, component: current_component) }
  let!(:selected_projects) { create_list(:budgeting_pipeline_project, 5, budget: budget, selected_at: Time.current) }
  let!(:other_projects) { create_list(:budgeting_pipeline_project, 10, budget: budget) }

  let!(:accountability_component) { create(:accountability_component, participatory_space: current_component.participatory_space) }

  include_context "when managing a component as an admin"

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
    visit_component_admin
    click_link "Exports proposals to results"
  end

  it "can export projects to accountability" do
    select translated(accountability_component.name), from: :accountability_export_target_component_id
    check :accountability_export_export_all_selected_projects

    expect { click_button "Export to results" }.to change(Decidim::Accountability::Result, :count).by(selected_projects.count)

    expect(page).to have_content("Proposals successfully exported to results")
  end

  context "when checking the exported details" do
    let!(:selected_projects) { create_list(:budgeting_pipeline_project, 1, budget: budget, selected_at: Time.current) }
    let(:project) { selected_projects.first }

    let(:result) { Decidim::Accountability::Result.order(:id).last }

    it "they match with the original projects" do
      perform_export

      expect(result.component).to eq(accountability_component)
      expect(result.title).to eq(project.title)
      expect(result.description).to eq(project.description)
      expect(result.progress).to eq(0)
      expect(result.status).to be_nil
      expect(result.weight).to eq(0)
    end

    context "with scope" do
      let!(:selected_projects) { create_list(:budgeting_pipeline_project, 1, budget: budget, selected_at: Time.current, scope: scope) }
      let(:scope) { create(:scope, organization: current_component.organization) }

      it "sets the correct scope" do
        perform_export

        expect(result.scope).to eq(scope)
      end

      context "when defined by budget" do
        let!(:selected_projects) { create_list(:budgeting_pipeline_project, 1, budget: budget, selected_at: Time.current) }
        let(:budget) { create(:budgeting_pipeline_budget, component: current_component, scope: scope) }

        it "sets the correct scope" do
          perform_export

          expect(result.scope).to eq(scope)
        end
      end
    end

    context "with category" do
      let!(:selected_projects) { create_list(:budgeting_pipeline_project, 1, budget: budget, selected_at: Time.current, category: category) }
      let(:category) { create(:category, participatory_space: current_component.participatory_space) }

      it "sets the correct category" do
        perform_export

        expect(result.category).to eq(category)
      end
    end

    context "with statuses" do
      let!(:status1) { create(:status, component: accountability_component, progress: 10) }
      let!(:status2) { create(:status, component: accountability_component, progress: 50) }

      it "sets the correct status for the result" do
        perform_export

        expect(result.progress).to eq(10)
        expect(result.status).to eq(status1)
      end
    end

    def perform_export
      select translated(accountability_component.name), from: :accountability_export_target_component_id
      check :accountability_export_export_all_selected_projects
      click_button "Export to results"
    end
  end
end
