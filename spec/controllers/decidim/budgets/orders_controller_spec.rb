# frozen_string_literal: true

require "spec_helper"

describe Decidim::Budgets::OrdersController, type: :controller do
  routes { Decidim::Budgets::Engine.routes }

  let(:user) { create(:user, :confirmed, organization: component.organization) }
  let!(:budget1) { create(:budgeting_pipeline_budget, component: component) }
  let!(:budget2) { create(:budgeting_pipeline_budget, component: component) }
  let(:component) { create(:budgeting_pipeline_component) }

  before do
    request.env["decidim.current_organization"] = component.organization
    request.env["decidim.current_participatory_space"] = component.participatory_space
    request.env["decidim.current_component"] = component
    sign_in user
  end

  describe "GET index" do
    context "with checked out orders" do
      let!(:vote) { create(:budgeting_pipeline_vote, order_count: 2, order_checked_out: true, user: user, component: component) }

      it "renders" do
        get :index

        expect(response).to render_template("decidim/budgets/orders/index")
      end
    end

    context "with no checked out orders" do
      let!(:vote) { create(:budgeting_pipeline_vote, order_count: 2, order_checked_out: false, user: user, component: component) }

      it "redirects" do
        get :index

        expect(response).to redirect_to("/processes/#{component.participatory_space.slug}/f/#{component.id}/projects")
      end
    end

    context "with no orders" do
      it "redirects" do
        get :index

        expect(response).to redirect_to("/processes/#{component.participatory_space.slug}/f/#{component.id}/projects")
      end
    end
  end
end
