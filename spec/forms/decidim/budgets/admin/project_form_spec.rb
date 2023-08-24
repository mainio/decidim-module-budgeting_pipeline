# frozen_string_literal: true

require "spec_helper"

describe Decidim::Budgets::Admin::ProjectForm do
  subject(:form) { described_class.from_params(attributes).with_context(context) }

  let(:organization) { create(:organization, tos_version: Time.current, available_locales: [:en]) }
  let(:context) do
    {
      current_organization: organization,
      current_component: current_component,
      current_participatory_space: participatory_process
    }
  end
  let(:participatory_process) { create(:participatory_process, organization: organization) }
  let(:current_component) { create(:budgets_component, participatory_space: participatory_process) }
  let(:budget) { create(:budget, component: current_component) }
  let(:title) do
    Decidim::Faker::Localized.sentence
  end
  let(:description) do
    Decidim::Faker::Localized.sentence
  end
  let(:budget_amount) { Faker::Number.number }
  let(:parent_scope) { create(:scope, organization: organization) }
  let(:scope) { create(:subscope, parent: parent_scope) }
  let(:scope_id) { scope.id }
  let(:category) { create(:category, participatory_space: participatory_process) }
  let(:category_id) { category.id }
  let(:selected) { nil }
  let(:latitude) { 40.1234 }
  let(:longitude) { 2.1234 }
  let(:address) { nil }
  let(:attributes) do
    {
      decidim_scope_id: scope_id,
      decidim_category_id: category_id,
      title_en: title[:en],
      description_en: description[:en],
      budget_amount: budget_amount,
      selected: selected,
      address: address,
      latitude: latitude,
      longitude: longitude
    }
  end
  let(:idea_ids) { [] }
  let(:plan_ids) { [] }

  context "when budget amount is zero" do
    let(:budget_amount) { 0 }

    it { is_expected.to be_valid }
  end

  context "when budget amount is negative" do
    let(:budget_amount) { -1 }

    it { is_expected.not_to be_valid }
  end

  describe "#map_model" do
    subject { described_class.from_model(project) }

    let(:project) { create(:project, budget: budget) }

    context "with ideas" do
      let(:idea_component) { create :idea_component, participatory_space: participatory_process }
      let(:idea1) { create(:idea, component: idea_component) }
      let(:idea_ids) { [idea1.id] }

      it "sets the idea_ids correctly" do
        project.link_resources([idea1], "included_ideas")
        expect(subject.idea_ids).to eq idea_ids
      end
    end

    context "with plans" do
      let(:plan_component) { create :plan_component, participatory_space: participatory_process }
      let(:plan1) { create(:plan, component: plan_component) }
      let(:plan_ids) { [plan1.id] }

      it "sets the idea_ids correctly" do
        project.link_resources([plan1], "included_plans")
        expect(subject.plan_ids).to eq plan_ids
      end
    end
  end

  describe "geocoded" do
    it "returns true if lat and longitude is set" do
      expect(subject.geocoded?).to be true
    end

    context "when latitiude is nil" do
      let(:latitude) { nil }

      it "returns false" do
        expect(subject.geocoded?).to be false
      end
    end

    context "when longitude is nil" do
      let(:longitude) { nil }

      it "returns false" do
        expect(subject.geocoded?).to be false
      end
    end
  end

  describe "#ideas" do
    subject { described_class.from_model(project).with_context(context) }

    let!(:project) { create(:project, budget: budget) }
    let(:idea_component) { create :idea_component, participatory_space: participatory_process }
    let!(:idea1) { create(:idea, component: idea_component) }

    context "with no ideas" do
      it "returns empty" do
        expect(subject.ideas).to match_array([])
      end
    end

    context "with ideas" do
      let!(:idea_ids) { [idea1.id] }

      before do
        subject.idea_ids = idea_ids
      end

      it "returns ideas" do
        expect(subject.ideas).to match_array([idea1])
      end
    end
  end

  describe "#plans" do
    subject { described_class.from_model(project).with_context(context) }

    let!(:project) { create(:project, budget: budget) }
    let(:plan_component) { create :plan_component, participatory_space: participatory_process }
    let!(:plan1) { create(:plan, component: plan_component) }

    context "with no plans" do
      it "returns empty" do
        expect(subject.plans).to match_array([])
      end
    end

    context "with plans" do
      let!(:plan_ids) { [plan1.id] }

      before do
        subject.plan_ids = plan_ids
      end

      it "returns ideas" do
        expect(subject.plans).to match_array([plan1])
      end
    end
  end
end
