# frozen_string_literal: true

require "spec_helper"

describe Decidim::Budgets::ProjectCell, type: :cell do
  controller Decidim::Budgets::ProjectsController

  subject { my_cell.call }

  let(:my_cell) { cell("decidim/budgets/project", model) }
  let!(:model) { create(:budgeting_pipeline_project, component: component) }
  let(:component) { create(:budgeting_pipeline_component) }

  before do
    allow(controller).to receive(:current_component).and_return(component)
  end

  context "when rendering a user idea" do
    it "renders the card" do
      expect(subject).to have_content(translated(model.title))
      expect(subject).to have_content(translated(model.summary))
      expect(subject).not_to have_content(strip_tags(translated(model.description)))
    end
  end
end
