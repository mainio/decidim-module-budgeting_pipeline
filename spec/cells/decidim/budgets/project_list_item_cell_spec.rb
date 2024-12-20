# frozen_string_literal: true

require "spec_helper"

describe Decidim::Budgets::ProjectVoteButtonCell, type: :cell do
  controller Decidim::Budgets::ProjectsController

  subject { my_cell.call }

  let(:my_cell) { cell("decidim/budgets/project_list_item", model) }
  let!(:model) { create(:budgeting_pipeline_project, component: component) }
  let(:component) { create(:budgeting_pipeline_component) }

  before do
    allow(controller).to receive(:current_component).and_return(component)
    allow_any_instance_of(Decidim::Budgets::ProjectVoteButtonCell).to receive(:budget_order_line_item_path).and_return("/line_item") # rubocop:disable RSpec/AnyInstance
  end

  context "when rendering a user idea" do
    it "renders the card" do
      expect(subject).to have_content(strip_tags(translated(model.description)))
    end
  end
end
