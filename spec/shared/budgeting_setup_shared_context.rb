# frozen_string_literal: true

shared_context "with budgeting setup" do
  let(:organization) { build(:organization, available_authorizations: ["dummy_authorization_handler"], tos_version: Time.current) }
  let(:component) { create(:budgeting_pipeline_component, permissions: component_permissions, participatory_space: create(:participatory_process, :with_steps, organization:)) }
  let(:step_settings) { { votes: voting_mode, show_votes: } }
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

  let!(:budget_one) { create(:budgeting_pipeline_budget, component:, total_budget: 200_000) }
  let!(:budget_two) { create(:budgeting_pipeline_budget, component:, total_budget: 100_000) }
  let!(:budget_three) { create(:budgeting_pipeline_budget, component:, total_budget: 120_000) }
  let!(:budget_four) { create(:budgeting_pipeline_budget, component:, total_budget: 80_000) }
  let!(:budget_five) { create(:budgeting_pipeline_budget, component:, total_budget: 110_000) }
  let(:budgets) { [budget_one, budget_two, budget_three, budget_four, budget_five] }

  let!(:budget_one_projects) { create_list(:budgeting_pipeline_project, 10, budget: budget_one, budget_amount: 40_000, paper_orders_count: 0) }
  let!(:budget_two_projects) { create_list(:budgeting_pipeline_project, 10, budget: budget_two, budget_amount: 20_000, paper_orders_count: 0) }
  let!(:budget_three_projects) { create_list(:budgeting_pipeline_project, 10, budget: budget_three, budget_amount: 24_000, paper_orders_count: 0) }
  let!(:budget_four_projects) { create_list(:budgeting_pipeline_project, 10, budget: budget_four, budget_amount: 16_000, paper_orders_count: 0) }
  let!(:budget_five_projects) { create_list(:budgeting_pipeline_project, 10, budget: budget_five, budget_amount: 22_000, paper_orders_count: 0) }

  let(:voted_budgets) { budgets.sample(2) }
  let!(:votes) do
    [].tap do |values|
      voted_budgets.each do |budget|
        10.times do
          vote = create(:budgeting_pipeline_vote, component:)
          order = create(:budgeting_pipeline_order, budget:, user: vote.user, vote:)
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

  let!(:user) { create(:user, :confirmed, organization:) }
  let!(:authorization) { create(:authorization, :granted, user:, name: "dummy_authorization_handler", unique_id: "123456789X") }

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
