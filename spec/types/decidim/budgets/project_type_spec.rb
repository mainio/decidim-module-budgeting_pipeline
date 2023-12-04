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

  describe "summary" do
    let(:query) { "{ summary { translations { text locale } } }" }

    let(:response_summary) do
      response["summary"]["translations"].to_h do |value|
        [value["locale"], value["text"]]
      end
    end

    it "returns the project summary" do
      actual_summary = model.summary.except("machine_translations")
      machine_translations = model.summary["machine_translations"]
      expect(response_summary).to match(actual_summary.merge(machine_translations))
    end
  end

  describe "mainImage" do
    let(:query) { "{ mainImage }" }

    before do
      model.main_image.attach(
        io: File.open(Decidim::Dev.asset("city.jpeg")),
        filename: "city.jpeg",
        content_type: "image/jpeg"
      )
    end

    it "returns the project's main image" do
      expect(response["mainImage"]).to match(model.attached_uploader(:main_image).url)
    end
  end

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
