# frozen_string_literal: true

require "spec_helper"

describe Decidim::Budgets::LineItemsController, type: :controller do
  routes { Decidim::Budgets::Engine.routes }

  let(:user) { create(:user, :confirmed, organization: component.organization) }
  let!(:budget) { create(:budgeting_pipeline_budget, component: component) }
  let(:component) { create(:budgeting_pipeline_component) }

  let(:project) { create(:budgeting_pipeline_project, budget: budget) }

  before do
    request.env["decidim.current_organization"] = component.organization
    request.env["decidim.current_participatory_space"] = component.participatory_space
    request.env["decidim.current_component"] = component
    sign_in user
  end

  describe "POST create" do
    shared_examples "creation error" do
      it "renders nothing with 422 status" do
        post :create, params: { budget_id: budget.id, project_id: project.id }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to eq ""
      end

      it "renders the correct template for XHR request" do
        post :create, format: :js, params: { budget_id: budget.id, project_id: project.id }

        expect(response).to render_template("decidim/budgets/line_items/update_budget_error")
      end
    end

    shared_examples "vote not allowed" do
      it "redirects the user" do
        post :create, params: { budget_id: budget.id, project_id: project.id }

        expect(response).to redirect_to("/")
      end
    end

    context "when everything is ok" do
      it "redirects the user back to the budgets path by default" do
        post :create, params: { budget_id: budget.id, project_id: project.id }

        expect(response).to redirect_to("/processes/#{component.participatory_space.slug}/f/#{component.id}/budgets/#{budget.id}")
      end

      it "renders the correct template for XHR request" do
        post :create, format: :js, params: { budget_id: budget.id, project_id: project.id }

        expect(response).to render_template("decidim/budgets/line_items/update_budget")
      end
    end

    context "when voting is not enabled" do
      before do
        component.update!(step_settings: { component.participatory_space.active_step.id => { votes: :disabled } })
      end

      include_examples "creation error"
    end

    context "when no more allocation is available" do
      let(:order) { create(:budgeting_pipeline_order, budget: budget, user: user) }

      before do
        order.projects << create(:budgeting_pipeline_project, budget: budget, budget_amount: budget.total_budget)
        order.save!
      end

      include_examples "creation error"
    end

    context "when the order is checked out" do
      let(:order) { create(:budgeting_pipeline_order, budget: budget, user: user) }

      before do
        order.update!(checked_out_at: Time.current)
      end

      include_examples "vote not allowed"
    end
  end
end
