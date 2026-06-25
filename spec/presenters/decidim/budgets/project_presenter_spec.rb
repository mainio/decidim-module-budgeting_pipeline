# frozen_string_literal: true

require "spec_helper"

describe Decidim::Budgets::ProjectPresenter do
  let(:organization) { create(:organization) }
  let(:participatory_process) { create(:participatory_process, organization:) }
  let(:component) { create(:budgeting_pipeline_component, participatory_space: participatory_process) }
  let(:budget) { create(:budgeting_pipeline_budget, component:) }
  let(:project) { create(:budgeting_pipeline_project, budget:) }

  subject { described_class.new(project) }

  describe "#project" do
    it "returns the project" do
      expect(subject.project).to eq(project)
    end
  end

  describe "#title" do
    it "returns the project title" do
      expect(subject.title).to eq(translated(project.title))
    end

    context "when project is nil" do
      subject { described_class.new(nil) }

      it "returns nil" do
        expect(subject.title).to be_nil
      end
    end

    context "with all_locales" do
      it "returns translations for all locales" do
        expect(subject.title(all_locales: true)).to be_a(Hash)
      end
    end
  end
end