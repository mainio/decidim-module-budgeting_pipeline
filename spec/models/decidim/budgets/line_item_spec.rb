# frozen_string_literal: true

require "spec_helper"

describe Decidim::Budgets::LineItem do
  let(:component) { create(:budgeting_pipeline_component) }
  let(:budget) { create(:budgeting_pipeline_budget, component: component, total_budget: 50_000) }
  let(:project1) { create(:budgeting_pipeline_project, budget: budget, budget_amount: 20_000) }
  let(:project2) { create(:budgeting_pipeline_project, budget: budget, budget_amount: 30_000) }
  let(:project3) { create(:budgeting_pipeline_project, budget: budget, budget_amount: 20_000) }
  let(:order) { create(:budgeting_pipeline_order, budget: budget) }

  before do
    order.projects << project1
    order.projects << project2
    order.save!
  end

  describe ".order_by_projects" do
    subject { order.line_items.order_by_projects }

    let(:expected_order) { order.line_items.sort_by { |item| translated(item.project.title) } }

    it "returns the projects in correct order" do
      expect(subject).to eq(expected_order)
    end

    context "when using another locale" do
      let(:expected_order) { order.line_items.sort_by { |item| item.project.title["ca"] } }

      around do |example|
        I18n.with_locale(:ca) { example.run }
      end

      it "returns the projects in correct order" do
        expect(subject).to eq(expected_order)
      end
    end
  end
end
