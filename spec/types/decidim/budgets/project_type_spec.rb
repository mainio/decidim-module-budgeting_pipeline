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

  describe "budgetAmount" do
    let(:query) { "{ budgetAmount }" }

    it "returns the project's budget amount" do
      expect(response["budgetAmount"]).to match(model.budget_amount)
    end
  end

  # Deprecated, keep for the time being.
  describe "budget_amount" do
    let(:query) { "{ budget_amount }" }

    it "returns the project's budget amount" do
      expect(response["budget_amount"]).to match(model.budget_amount)
    end
  end

  describe "budgetAmountMin" do
    let(:model) { create(:budgeting_pipeline_project, component: component, budget_amount_min: 10_000) }

    let(:query) { "{ budgetAmountMin }" }

    it "returns the project's minimum budget amount" do
      expect(response["budgetAmountMin"]).to match(model.budget_amount_min)
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
