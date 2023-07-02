# frozen_string_literal: true

require "spec_helper"

describe Decidim::Budgets::OrderSummariesMailer, type: :mailer do
  describe "#order_summaries" do
    let(:mail) { described_class.order_summaries([order1, order2], user) }

    let(:organization) { create(:organization, tos_version: Time.current) }
    let(:component) { create(:budgeting_pipeline_component, organization: organization) }
    let(:user) { create(:user, :confirmed, organization: organization) }
    let(:budget1) { create(:budgeting_pipeline_budget, component: component) }
    let(:budget2) { create(:budgeting_pipeline_budget, component: component) }
    let(:order1) { create(:budgeting_pipeline_order, :with_projects, budget: budget1, user: user) }
    let(:order2) { create(:budgeting_pipeline_order, :with_projects, budget: budget2, user: user) }

    before do
      order1.update!(checked_out_at: Time.current)
      order2.update!(checked_out_at: Time.current)
    end

    it "adds the correct subject" do
      expect(mail.subject).to eq("You voted in #{translated(budget1.title)}, #{translated(budget2.title)}")
    end

    it "adds the budgets to the body" do
      expect(email_body(mail)).to include(translated(budget1.title))
      expect(email_body(mail)).to include(translated(budget2.title))
    end

    it "adds the selected projects to the body" do
      order1.projects.each do |project|
        expect(email_body(mail)).to include("<li>#{translated(project.title)}</li>")
      end
      order2.projects.each do |project|
        expect(email_body(mail)).to include("<li>#{translated(project.title)}</li>")
      end
    end

    context "when there are no orders" do
      let(:mail) { described_class.order_summaries([], user) }

      it "does not send the email" do
        expect(mail.to).to be_nil
      end
    end
  end
end
