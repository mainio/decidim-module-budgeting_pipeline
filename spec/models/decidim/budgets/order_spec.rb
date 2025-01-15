# frozen_string_literal: true

require "spec_helper"

describe Decidim::Budgets::Order do
  let(:component) { create(:budgeting_pipeline_component, vote_rule_settings:) }
  let(:vote_rule_settings) do
    {
      vote_rule_threshold_percent_enabled: true,
      vote_threshold_percent: 70,
      vote_rule_minimum_budget_projects_enabled: false,
      vote_minimum_budget_projects_number: 0,
      vote_rule_selected_projects_enabled: false,
      vote_selected_projects_minimum: 0,
      vote_selected_projects_maximum: 1
    }
  end
  let(:budget) { create(:budgeting_pipeline_budget, component:, total_budget: 40_000) }
  let(:project_one) { create(:budgeting_pipeline_project, budget:, budget_amount: 20_000) }
  let(:project_two) { create(:budgeting_pipeline_project, budget:, budget_amount: 30_000) }

  shared_context "with first project selected" do
    before { order.projects << project_one }
  end

  shared_context "with second project selected" do
    before { order.projects << project_two }
  end

  describe ".order_by_budgets" do
    subject { described_class.where(budget: [budget_one, budget_two, budget_three]).order_by_budgets }

    let(:budget_one) { create(:budgeting_pipeline_budget, component:, weight: 3) }
    let(:budget_two) { create(:budgeting_pipeline_budget, component:, weight: 1) }
    let(:budget_three) { create(:budgeting_pipeline_budget, component:, weight: 2) }
    let!(:budget_one_projects) { create_list(:budgeting_pipeline_project, 10, budget: budget_one) }
    let!(:budget_two_projects) { create_list(:budgeting_pipeline_project, 5, budget: budget_two) }
    let!(:budget_three_projects) { create_list(:budgeting_pipeline_project, 3, budget: budget_three) }
    let(:order_amounts) do
      {
        budget_one.id => 4,
        budget_two.id => 3,
        budget_three.id => 2
      }
    end

    before do
      (budget_one_projects + budget_two_projects + budget_three_projects).each do |project|
        orders = create_list(:budgeting_pipeline_order, order_amounts[project.budget.id], budget: project.budget)
        orders.each do |order|
          order.projects << project
          order.checked_out_at = Time.current
          order.save!(validate: false)
        end
      end
    end

    it "orders the results by the budget weights" do
      indexes = {}
      indexes[budget_two.id] = order_amounts[budget_two.id] * budget_two_projects.count
      indexes[budget_three.id] = indexes[budget_two.id] + (order_amounts[budget_three.id] * budget_three_projects.count)
      indexes[budget_one.id] = indexes[budget_three.id] + (order_amounts[budget_one.id] * budget_one_projects.count)
      subject.each_with_index do |order, idx|
        msg = "Expected budget ##{order.budget.id} at index #{idx}"
        if idx < indexes[budget_two.id]
          expect(order.budget).to eq(budget_two), msg
        elsif idx < indexes[budget_three.id]
          expect(order.budget).to eq(budget_three), msg
        else
          expect(order.budget).to eq(budget_one), msg
        end
      end
    end
  end

  describe "#allocation_available_for?" do
    subject { order.allocation_available_for?(project_two) }

    let!(:order) { create(:budgeting_pipeline_order, budget:) }

    context "when there is enough budget left" do
      it { is_expected.to be(true) }
    end

    context "when the budget is not sufficient" do
      include_context "with first project selected"

      it { is_expected.to be(false) }
    end

    context "with projects rule" do
      let(:vote_rule_settings) do
        {
          vote_rule_threshold_percent_enabled: false,
          vote_threshold_percent: 70,
          vote_rule_minimum_budget_projects_enabled: false,
          vote_minimum_budget_projects_number: 0,
          vote_rule_selected_projects_enabled: true,
          vote_selected_projects_minimum: 0,
          vote_selected_projects_maximum: 1
        }
      end

      context "when there are selections left" do
        it { is_expected.to be(true) }
      end

      context "when there are no selections left" do
        include_context "with first project selected"

        it { is_expected.to be(false) }
      end
    end
  end

  describe "#unused_allocation" do
    subject { order.unused_allocation }

    let!(:order) { create(:budgeting_pipeline_order, budget:) }

    context "when no projects are selected" do
      it { is_expected.to eq(budget.total_budget) }
    end

    context "with a selected project" do
      include_context "with first project selected"

      it { is_expected.to eq(budget.total_budget - project_one.budget_amount) }
    end

    context "with projects rule" do
      let(:vote_rule_settings) do
        {
          vote_rule_threshold_percent_enabled: false,
          vote_threshold_percent: 70,
          vote_rule_minimum_budget_projects_enabled: false,
          vote_minimum_budget_projects_number: 0,
          vote_rule_selected_projects_enabled: true,
          vote_selected_projects_minimum: 0,
          vote_selected_projects_maximum: 1
        }
      end

      context "when no projects are selected" do
        it { is_expected.to eq(1) }
      end

      context "when there are no selections left" do
        include_context "with first project selected"

        it { is_expected.to eq(0) }
      end
    end
  end

  describe "#allocation_exceeded?" do
    subject { order.allocation_exceeded? }

    let!(:order) { create(:budgeting_pipeline_order, budget:) }

    context "when no projects are selected" do
      it { is_expected.to be(false) }
    end

    context "with projects selected exceeding the budget" do
      include_context "with first project selected"
      include_context "with second project selected"

      it { is_expected.to be(true) }
    end

    context "with projects rule" do
      let(:vote_rule_settings) do
        {
          vote_rule_threshold_percent_enabled: false,
          vote_threshold_percent: 70,
          vote_rule_minimum_budget_projects_enabled: false,
          vote_minimum_budget_projects_number: 0,
          vote_rule_selected_projects_enabled: true,
          vote_selected_projects_minimum: 0,
          vote_selected_projects_maximum: 1
        }
      end

      context "when no projects are selected" do
        it { is_expected.to be(false) }
      end

      context "when too many projects are selected" do
        include_context "with first project selected"
        include_context "with second project selected"

        it { is_expected.to be(true) }
      end
    end
  end

  describe "#valid_for_checkout?" do
    subject { order.valid_for_checkout? }

    let!(:order) { create(:budgeting_pipeline_order, budget:) }

    context "with the minimum projects rule" do
      let(:minimum_projects) { 0 }
      let(:vote_rule_settings) do
        {
          vote_rule_threshold_percent_enabled: false,
          vote_threshold_percent: 70,
          vote_rule_minimum_budget_projects_enabled: true,
          vote_minimum_budget_projects_number: minimum_projects,
          vote_rule_selected_projects_enabled: false,
          vote_selected_projects_minimum: 0,
          vote_selected_projects_maximum: 1
        }
      end

      context "when no projects are selected" do
        it { is_expected.to be(true) }
      end

      context "when not enough projects are selected" do
        let(:minimum_projects) { 1 }

        it { is_expected.to be(false) }
      end
    end

    context "with the projects rule" do
      let(:minimum_projects) { 0 }
      let(:vote_rule_settings) do
        {
          vote_rule_threshold_percent_enabled: false,
          vote_threshold_percent: 70,
          vote_rule_minimum_budget_projects_enabled: false,
          vote_minimum_budget_projects_number: 0,
          vote_rule_selected_projects_enabled: true,
          vote_selected_projects_minimum: minimum_projects,
          vote_selected_projects_maximum: 1
        }
      end

      context "when no projects are selected" do
        it { is_expected.to be(true) }
      end

      context "when not enough projects are selected" do
        let(:minimum_projects) { 1 }

        it { is_expected.to be(false) }
      end

      context "when maximum projects are exceeded" do
        include_context "with first project selected"
        include_context "with second project selected"

        it { is_expected.to be(false) }
      end
    end

    context "with the budget amount rule" do
      let(:threshold_percentage) { 50 }
      let(:vote_rule_settings) do
        {
          vote_rule_threshold_percent_enabled: true,
          vote_threshold_percent: threshold_percentage,
          vote_rule_minimum_budget_projects_enabled: false,
          vote_minimum_budget_projects_number: 0,
          vote_rule_selected_projects_enabled: false,
          vote_selected_projects_minimum: 0,
          vote_selected_projects_maximum: 1
        }
      end

      context "when no projects are selected" do
        it { is_expected.to be(false) }
      end

      context "when not enough projects are selected" do
        let(:threshold_percentage) { 70 }

        include_context "with first project selected"

        it { is_expected.to be(false) }
      end

      context "when too many projects are selected" do
        include_context "with first project selected"
        include_context "with second project selected"

        it { is_expected.to be(false) }
      end
    end
  end
end
