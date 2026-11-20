# frozen_string_literal: true

require "spec_helper"

describe Decidim::ActionLog do
  subject do
    described_class.create!(
      user:,
      organization:,
      action:,
      resource:,
      resource_id: resource.id,
      resource_type: resource.class.name,
      participatory_space:,
      component:,
      area: nil,
      scope: nil,
      version_id: 1,
      extra: extra_data,
      visibility: "private-only"
    )
  end

  let(:organization) { create(:organization, tos_version: Time.current) }
  let(:user) { create(:user, organization:) }
  let(:action) { :create }
  let(:participatory_space) { create(:participatory_process, organization:) }
  let(:component) { create(:budgeting_pipeline_component, participatory_space:) }
  let(:resource) { create(:budgeting_pipeline_vote, component:) }
  let(:extra_data) { {} }

  it "accepts a private-only type log entry" do
    expect(subject).to be_a(described_class)
  end
end
