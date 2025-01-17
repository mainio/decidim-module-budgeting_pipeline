# frozen_string_literal: true

require "spec_helper"

describe Decidim::Budgets::ResultsController do
  routes { Decidim::Budgets::Engine.routes }

  let(:user) { create(:user, :confirmed, organization: component.organization) }
  let(:component) { create(:budgeting_pipeline_component) }

  before do
    request.env["decidim.current_organization"] = component.organization
    request.env["decidim.current_participatory_space"] = component.participatory_space
    request.env["decidim.current_component"] = component
    sign_in user
  end

  describe "GET index" do
    context "when show votes is enabled" do
      before do
        component.update!(step_settings: { component.participatory_space.active_step.id => { show_votes: true } })
      end

      it "renders" do
        get :show

        expect(response).to render_template("decidim/budgets/results/show")
      end
    end

    context "when show votes is disabled" do
      it "renders" do
        get :show

        expect(response).to redirect_to("/processes/#{component.participatory_space.slug}/f/#{component.id}/projects")
      end
    end
  end
end
