# frozen_string_literal: true

require "spec_helper"

describe Decidim::Budgets::Order do
  let(:component) { create(:budgeting_pipeline_component, vote_rule_settings: vote_rule_settings) }
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
  let(:budget) { create(:budgeting_pipeline_budget, component: component, total_budget: 40_000) }
  let(:project1) { create(:budgeting_pipeline_project, budget: budget, budget_amount: 20_000) }
  let(:project2) { create(:budgeting_pipeline_project, budget: budget, budget_amount: 30_000) }

  shared_context "with first project selected" do
    before { order.projects << project1 }
  end

  shared_context "with second project selected" do
    before { order.projects << project2 }
  end

  describe ".order_by_budgets" do
    subject { described_class.where(budget: [budget1, budget2, budget3]).order_by_budgets }

    let(:budget1) { create(:budgeting_pipeline_budget, component: component, weight: 3) }
    let(:budget2) { create(:budgeting_pipeline_budget, component: component, weight: 1) }
    let(:budget3) { create(:budgeting_pipeline_budget, component: component, weight: 2) }
    let!(:budget1_projects) { create_list(:budgeting_pipeline_project, 10, budget: budget1) }
    let!(:budget2_projects) { create_list(:budgeting_pipeline_project, 5, budget: budget2) }
    let!(:budget3_projects) { create_list(:budgeting_pipeline_project, 3, budget: budget3) }
    let(:order_amounts) do
      {
        budget1.id => 4,
        budget2.id => 3,
        budget3.id => 2
      }
    end

    before do
      (budget1_projects + budget2_projects + budget3_projects).each do |project|
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
      indexes[budget2.id] = order_amounts[budget2.id] * budget2_projects.count
      indexes[budget3.id] = indexes[budget2.id] + (order_amounts[budget3.id] * budget3_projects.count)
      indexes[budget1.id] = indexes[budget3.id] + (order_amounts[budget1.id] * budget1_projects.count)
      subject.each_with_index do |order, idx|
        msg = "Expected budget ##{order.budget.id} at index #{idx}"
        if idx < indexes[budget2.id]
          expect(order.budget).to eq(budget2), msg
        elsif idx < indexes[budget3.id]
          expect(order.budget).to eq(budget3), msg
        else
          expect(order.budget).to eq(budget1), msg
        end
      end
    end
  end

  describe "#allocation_available_for?" do
    subject { order.allocation_available_for?(project2) }

    let!(:order) { create(:budgeting_pipeline_order, budget: budget) }

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

    let!(:order) { create(:budgeting_pipeline_order, budget: budget) }

    context "when no projects are selected" do
      it { is_expected.to eq(budget.total_budget) }
    end

    context "with a selected project" do
      include_context "with first project selected"

      it { is_expected.to eq(budget.total_budget - project1.budget_amount) }
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

    let!(:order) { create(:budgeting_pipeline_order, budget: budget) }

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

    let!(:order) { create(:budgeting_pipeline_order, budget: budget) }

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
