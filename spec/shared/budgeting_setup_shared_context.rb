# frozen_string_literal: true

shared_context "with budgeting setup" do
  let(:organization) { build(:organization, available_authorizations: ["dummy_authorization_handler"], tos_version: Time.current) }
  let(:component) { create(:budgeting_pipeline_component, permissions: component_permissions, organization: organization) }
  let(:step_settings) { { votes: voting_mode, show_votes: show_votes } }
  let(:voting_mode) { :enabled }
  let(:show_votes) { true }
  let(:requires_authorization) { true }
  let(:component_permissions) do
    if requires_authorization
      {
        "vote" => {
          "authorization_handlers" => {
            "dummy_authorization_handler" => {
              "options" => {}
            }
          }
        }
      }
    else
      {}
    end
  end

  let!(:budget1) { create(:budgeting_pipeline_budget, component: component, total_budget: 200_000) }
  let!(:budget2) { create(:budgeting_pipeline_budget, component: component, total_budget: 100_000) }
  let!(:budget3) { create(:budgeting_pipeline_budget, component: component, total_budget: 120_000) }
  let!(:budget4) { create(:budgeting_pipeline_budget, component: component, total_budget: 80_000) }
  let!(:budget5) { create(:budgeting_pipeline_budget, component: component, total_budget: 110_000) }
  let(:budgets) { [budget1, budget2, budget3, budget4, budget5] }

  let!(:budget1_projects) { create_list(:budgeting_pipeline_project, 10, budget: budget1, budget_amount: 40_000, paper_orders_count: 0) }
  let!(:budget2_projects) { create_list(:budgeting_pipeline_project, 10, budget: budget2, budget_amount: 20_000, paper_orders_count: 0) }
  let!(:budget3_projects) { create_list(:budgeting_pipeline_project, 10, budget: budget3, budget_amount: 24_000, paper_orders_count: 0) }
  let!(:budget4_projects) { create_list(:budgeting_pipeline_project, 10, budget: budget4, budget_amount: 16_000, paper_orders_count: 0) }
  let!(:budget5_projects) { create_list(:budgeting_pipeline_project, 10, budget: budget5, budget_amount: 22_000, paper_orders_count: 0) }

  let(:voted_budgets) { budgets.sample(2) }
  let!(:votes) do
    [].tap do |values|
      voted_budgets.each do |budget|
        10.times do
          vote = create(:budgeting_pipeline_vote, component: component)
          order = create(:budgeting_pipeline_order, budget: budget, user: vote.user, vote: vote)
          Array(budget.projects.sample(rand(0..5))).each do |project|
            order.projects << project
            project.update!(paper_orders_count: rand(1..10)) if project.paper_orders_count < 1
          end
          order.checked_out_at = Time.current
          order.save!

          values << vote
        end
      end
    end
  end

  let!(:user) { create(:user, :confirmed, organization: organization) }
  let!(:authorization) { create(:authorization, :granted, user: user, name: "dummy_authorization_handler", unique_id: "123456789X") }

  before do
    component.update!(step_settings: { component.participatory_space.active_step.id => step_settings }) if step_settings.present?

    switch_to_host(organization.host)
  end

  def visit_component
    page.visit decidim_budgets.projects_path
  end

  def visit_project(project)
    page.visit decidim_budgets.project_path(project)
  end

  def visit_results
    page.visit decidim_budgets.results_path
  end

  def visit_voting
    page.visit decidim_budgets.vote_path
  end

  def visit_voting_preview
    page.visit decidim_budgets.preview_vote_path
  end

  def decidim_budgets
    @decidim_budgets ||= Decidim::EngineRouter.main_proxy(component)
  end
end
