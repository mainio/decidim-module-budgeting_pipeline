# frozen_string_literal: true

require "spec_helper"

describe Decidim::Budgets::LinkedResourcesController do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, :confirmed, organization:) }
  let(:participatory_process) { create(:participatory_process, organization:) }
  let(:component) { create(:budgeting_pipeline_component, participatory_space: participatory_process) }
  let(:budget) { create(:budgeting_pipeline_budget, component:) }
  let(:project) { create(:budgeting_pipeline_project, budget:) }
  let(:proposal_component) { create(:proposal_component, participatory_space: participatory_process) }
  let(:proposal) { create(:proposal, component: proposal_component) }

  before do
    request.env["decidim.current_organization"] = organization
    request.env["decidim.current_participatory_space"] = participatory_process
    request.env["decidim.current_component"] = component
    sign_in user
  end

  describe "GET show" do
    context "when the project does not exist" do
      it "raises a routing error" do
        expect do
          get :show, params: { project_id: 0, id: proposal.to_gid.to_s }
        end.to raise_error(ActionController::RoutingError)
      end
    end

    context "when the resource does not exist" do
      it "raises a routing error" do
        expect do
          get :show, params: { project_id: project.id, id: "invalid" }
        end.to raise_error(ActionController::RoutingError)
      end
    end

    context "when the resource is withdrawn" do
      before { proposal.update!(withdrawn_at: Time.current) }

      it "raises a routing error" do
        expect do
          get :show, params: { project_id: project.id, id: proposal.to_gid.to_s }
        end.to raise_error(ActionController::RoutingError)
      end
    end

    context "when the resource is valid" do
      it "redirects to the resource path" do
        get :show, params: { project_id: project.id, id: proposal.to_gid.to_s }
        expect(response).to redirect_to(resource_locator(proposal).path)
      end
    end

    context "when the resource is another project" do
      let(:other_project) { create(:budgeting_pipeline_project, budget:) }

      it "redirects to the project path" do
        get :show, params: { project_id: project.id, id: other_project.to_gid.to_s }
        expect(response).to redirect_to(resource_locator([other_project.budget, other_project]).path)
      end
    end
  end
end
