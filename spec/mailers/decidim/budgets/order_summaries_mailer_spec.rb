# frozen_string_literal: true

require "spec_helper"

describe Decidim::Budgets::OrderSummariesMailer do
  describe "#order_summaries" do
    let(:mail) { described_class.order_summaries([order_one, order_two], user) }

    let(:organization) { create(:organization, tos_version: Time.current) }
    let(:component) { create(:budgeting_pipeline_component, organization:) }
    let(:user) { create(:user, :confirmed, organization:) }
    let(:budget_one) { create(:budgeting_pipeline_budget, component:) }
    let(:budget_two) { create(:budgeting_pipeline_budget, component:) }
    let(:order_one) { create(:budgeting_pipeline_order, :with_projects, budget: budget_one, user:) }
    let(:order_two) { create(:budgeting_pipeline_order, :with_projects, budget: budget_two, user:) }

    before do
      order_one.update!(checked_out_at: Time.current)
      order_two.update!(checked_out_at: Time.current)
    end

    it "adds the correct subject" do
      expect(mail.subject).to eq("You voted in #{translated(budget_one.title)}, #{translated(budget_two.title)}")
    end

    it "adds the budgets to the body" do
      expect(email_body(mail)).to include(decidim_sanitize(translated(budget_one.title)))
      expect(email_body(mail)).to include(decidim_sanitize(translated(budget_two.title)))
    end

    it "adds the selected projects to the body" do
      order_one.projects.each do |project|
        expect(email_body(mail)).to include("<li>#{decidim_escape_translated(project.title)}</li>")
      end
      order_two.projects.each do |project|
        expect(email_body(mail)).to include("<li>#{decidim_escape_translated(project.title)}</li>")
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
