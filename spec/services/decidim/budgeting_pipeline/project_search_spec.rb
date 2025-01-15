# frozen_string_literal: true

require "spec_helper"

describe Decidim::BudgetingPipeline::ProjectSearch do
  subject { described_class.new(base_query, params, options) }

  let(:base_query) { Decidim::Budgets::Project.where(component:) }
  let(:params) { {} }
  let(:options) { { component: } }

  let(:component) { create(:budgeting_pipeline_component) }
  let!(:budget_one) { create(:budget, component:) }
  let!(:budget_two) { create(:budget, component:) }
  let!(:projects) do
    [].tap do |list|
      list << create(:project, title: { en: "First project" }, budget: budget_one)
      list << create(:project, title: { en: "Second project" }, budget: budget_one)
      list << create(:project, title: { en: "Third project" }, budget: budget_two)
      list << create(:project, title: { en: "Fourth project" }, budget: budget_two)
    end
  end

  context "when the search query matches all projects" do
    let(:params) { { search_text_cont: "project" } }

    it "finds the correct projects" do
      expect(subject.result.count).to eq(4)
    end
  end

  context "when the search query matches a single project" do
    let(:params) { { search_text_cont: "first" } }

    it "finds the correct project" do
      expect(subject.result.count).to eq(1)
      expect(subject.result.first).to eq(projects[0])
    end
  end

  context "with linked plans" do
    let(:plans_component) { create(:plan_component, participatory_space: component.participatory_space) }

    let!(:plans) do
      [].tap do |list|
        list << create(:plan, title: { en: "Primary plan" }, component: plans_component)
        list << create(:plan, title: { en: "Secondary plan" }, component: plans_component)
        list << create(:plan, title: { en: "Tertiary plan" }, component: plans_component)
        list << create(:plan, title: { en: "Quaternary plan" }, component: plans_component)
      end
    end

    let!(:resource_links) do
      projects.each_with_index.map do |project, idx|
        create(:resource_link, name: "included_plans", from: project, to: plans[idx])
      end
    end

    context "when the search query matches all plans" do
      let(:params) { { search_text_cont: "plan" } }

      it "finds the correct projects" do
        expect(subject.result.count).to eq(4)
      end
    end

    context "when the search query matches a single plan" do
      let(:params) { { search_text_cont: "quaternary" } }

      it "finds the correct project" do
        expect(subject.result.count).to eq(1)
        expect(subject.result.first).to eq(projects[3])
      end
    end

    context "when searching with searchable plan content" do
      let(:section) { create(:section, :field_text, component: plans_component) }
      let!(:content) { create(:content, section:, plan: plans.first, body: { en: "This content should be discoverable through the search." }) }

      let(:params) { { search_text_cont: "discoverable" } }

      it "finds the correct project" do
        expect(subject.result.count).to eq(1)
        expect(subject.result.first).to eq(projects[0])
      end
    end
  end
end
