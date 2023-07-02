# frozen_string_literal: true

require "spec_helper"

describe Decidim::Budgets::SendOrderSummariesJob do
  subject { described_class.perform_now(vote, user) }

  let!(:organization) { create(:organization, tos_version: Time.current) }
  let(:user) { create(:user, :confirmed, organization: organization) }
  let(:component) { create(:budgeting_pipeline_component, organization: organization) }
  let(:vote) { create(:budgeting_pipeline_vote, order_count: 2, user: user, component: component) }

  before do
    clear_emails

    perform_enqueued_jobs { subject }
  end

  it "delivers the mail" do
    expect(last_email.to).to eq([user.email])
  end

  context "when the user does not have an email" do
    let(:user) { create(:user, :confirmed, email: "", managed: true, organization: organization) }

    it "does not send email" do
      expect(last_email).to be_nil
    end
  end

  context "when no user is provided" do
    subject { described_class.perform_now(vote, nil) }

    it "does not send email" do
      expect(last_email).to be_nil
    end
  end
end
