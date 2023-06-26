# frozen_string_literal: true

require "spec_helper"
require "decidim/api/test/type_context"

describe Decidim::Budgets::ProjectType do
  include_context "with a graphql class type"

  let(:model) { create(:budgeting_pipeline_project, component: component) }
  let(:participatory_space) { create(:participatory_process) }
  let(:component) { create(:budgeting_pipeline_component, participatory_space: participatory_space) }
  let(:proposal) { create(:proposal, component: proposals_component) }
  let(:proposals_component) { create(:proposal_component, participatory_space: participatory_space) }

  describe "linkedResources" do
    let(:query) { "{ linkedResources { ...on Proposal { id } } }" }

    before do
      model.link_resources([proposal], "included_proposals")
    end

    it "returns the user" do
      expect(response["linkedResources"]).to eq([{ "id" => proposal.id.to_s }])
    end
  end
end
