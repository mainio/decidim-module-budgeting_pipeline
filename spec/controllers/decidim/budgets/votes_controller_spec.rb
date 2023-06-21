# frozen_string_literal: true

require "spec_helper"

describe Decidim::Budgets::VotesController, type: :controller do
  routes { Decidim::Budgets::Engine.routes }

  let(:organization) { build(:organization, available_authorizations: ["dummy_authorization_handler"]) }
  let(:user) { create(:user, :confirmed, organization: component.organization) }
  let(:component) do
    create(
      :budgeting_pipeline_component,
      permissions: {
        "vote" => {
          "authorization_handlers" => {
            "dummy_authorization_handler" => {
              "options" => {}
            }
          }
        }
      }
    )
  end

  let(:step_settings) { nil }

  before do
    component.update!(step_settings: { component.participatory_space.active_step.id => step_settings }) if step_settings.present?

    request.env["decidim.current_organization"] = component.organization
    request.env["decidim.current_participatory_space"] = component.participatory_space
    request.env["decidim.current_component"] = component
    sign_in user
  end

  shared_context "with existing orders" do
    let!(:budget1) { create(:budgeting_pipeline_budget, component: component) }
    let!(:budget2) { create(:budgeting_pipeline_budget, component: component) }
    let!(:order1) { create(:order, budget: budget1, user: user) }
    let!(:order2) { create(:order, budget: budget2, user: user) }
  end

  shared_examples "ensured voting open" do
    context "when voting is not open" do
      context "with show votes enabled" do
        let(:step_settings) { { votes: :disabled, show_votes: true } }

        it "redirects to results" do
          do_request

          expect(flash[:warning]).to eq("You cannot vote at this moment.")
          expect(response).to redirect_to("/processes/#{component.participatory_space.slug}/f/#{component.id}/results")
        end
      end

      context "with show votes disabled" do
        let(:step_settings) { { votes: :disabled, show_votes: false } }

        it "redirects to projects" do
          do_request

          expect(flash[:warning]).to eq("You cannot vote at this moment.")
          expect(response).to redirect_to("/processes/#{component.participatory_space.slug}/f/#{component.id}/projects")
        end
      end
    end
  end

  shared_examples "ensured voting can be entered" do
    include_examples "ensured voting open"

    context "when voting is open" do
      let(:step_settings) { { votes: :enabled } }

      context "when the user is not authorized" do
        it "redirects to vote" do
          do_request

          expect(flash[:warning]).to eq("You have to identify yourself in order to vote.")
          expect(response).to redirect_to("/processes/#{component.participatory_space.slug}/f/#{component.id}/vote")
        end
      end

      context "when the user is authorized" do
        let!(:authorization) { create(:authorization, :granted, user: user, name: "dummy_authorization_handler", unique_id: "123456789X") }

        context "when the user has voted" do
          let!(:vote) { create(:budgeting_pipeline_vote, order_count: 2, order_checked_out: true, user: user, component: component) }

          it "redirects to projects" do
            do_request

            expect(flash[:warning]).to eq("You have already voted.")
            expect(response).to redirect_to("/processes/#{component.participatory_space.slug}/f/#{component.id}/projects")
          end
        end
      end
    end
  end

  shared_examples "ensured voting has orders" do
    include_examples "ensured voting can be entered"

    context "when voting is open and the user is authorized" do
      let(:step_settings) { { votes: :enabled } }
      let!(:authorization) { create(:authorization, :granted, user: user, name: "dummy_authorization_handler", unique_id: "123456789X") }

      context "when there are no orders available" do
        it "redirects to budgets selection" do
          do_request

          expect(response).to redirect_to("/processes/#{component.participatory_space.slug}/f/#{component.id}/vote/budgets")
        end
      end
    end
  end

  shared_examples "ensured orders valid" do
    include_examples "ensured voting has orders"

    context "when orders are not valid" do
      let(:step_settings) { { votes: :enabled } }
      let!(:authorization) { create(:authorization, :granted, user: user, name: "dummy_authorization_handler", unique_id: "123456789X") }

      include_context "with backwards compatibility" do
        let(:projects_rule_total_projects) { 2 }
      end
      include_context "with existing orders"

      before do
        order1.projects << create(:project, budget_amount: 10, budget: budget1)
        order1.projects << create(:project, budget_amount: 20, budget: budget1)
        order1.save!
      end

      it "redirects to projects selection" do
        do_request

        expect(response).to redirect_to("/processes/#{component.participatory_space.slug}/f/#{component.id}/vote/projects")
      end
    end
  end

  describe "GET show" do
    include_examples "ensured voting open" do
      let(:perform_request) { ->(_) { get :show } }
    end
  end

  describe "GET budgets" do
    include_examples "ensured voting can be entered" do
      let(:perform_request) { ->(_) { get :budgets } }
    end

    context "when everything is set for voting" do
      let(:step_settings) { { votes: :enabled } }
      let!(:authorization) { create(:authorization, :granted, user: user, name: "dummy_authorization_handler", unique_id: "123456789X") }

      it "renders" do
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST start" do
    include_examples "ensured voting can be entered" do
      let(:perform_request) { ->(_) { post :start } }
    end

    context "when everything is set for voting" do
      let(:step_settings) { { votes: :enabled } }
      let!(:authorization) { create(:authorization, :granted, user: user, name: "dummy_authorization_handler", unique_id: "123456789X") }

      context "when budgets are not selected" do
        it "renders budgets" do
          post :start

          expect(flash[:alert]).to eq("Failed to select voting area, please try again.")
          expect(response).to render_template(:budgets)
        end
      end

      context "when budgets are selected" do
        let!(:budget1) { create(:budgeting_pipeline_budget, component: component) }
        let!(:budget2) { create(:budgeting_pipeline_budget, component: component) }

        it "redirects to projects selection" do
          post :start, params: { budget_ids: [budget1.id, budget2.id] }

          expect(response).to redirect_to("/processes/#{component.participatory_space.slug}/f/#{component.id}/vote/projects")
        end
      end
    end
  end

  describe "GET projects" do
    include_examples "ensured voting has orders" do
      let(:perform_request) { ->(_) { get :projects } }
    end

    context "when everything is set for voting" do
      let(:step_settings) { { votes: :enabled } }
      let!(:authorization) { create(:authorization, :granted, user: user, name: "dummy_authorization_handler", unique_id: "123456789X") }

      context "when there are orders available" do
        include_context "with backwards compatibility"
        include_context "with existing orders"

        it "renders" do
          do_request

          expect(response).to have_http_status(:ok)
        end
      end
    end
  end

  describe "GET preview" do
    include_examples "ensured orders valid" do
      let(:perform_request) { ->(_) { get :preview } }
    end

    context "when everything is set for voting" do
      let(:step_settings) { { votes: :enabled } }
      let!(:authorization) { create(:authorization, :granted, user: user, name: "dummy_authorization_handler", unique_id: "123456789X") }

      context "when there are orders available" do
        include_context "with backwards compatibility"
        include_context "with existing orders"

        it "renders" do
          do_request

          expect(response).to have_http_status(:ok)
        end
      end
    end
  end

  describe "POST create" do
    include_examples "ensured orders valid" do
      let(:perform_request) { ->(_) { post :create } }
    end

    context "when everything is set for voting" do
      let(:step_settings) { { votes: :enabled } }
      let!(:authorization) { create(:authorization, :granted, user: user, name: "dummy_authorization_handler", unique_id: "123456789X") }

      include_context "with backwards compatibility"
      include_context "with existing orders"

      it "redirects to projects" do
        post :create

        expect(response).to redirect_to("/processes/#{component.participatory_space.slug}/f/#{component.id}/projects")
      end

      it "checks out the orders" do
        post :create

        expect(order1.reload.checked_out?).to be(true)
        expect(order2.reload.checked_out?).to be(true)
      end

      context "with show votes enabled" do
        let(:step_settings) { { votes: :disabled, show_votes: true } }

        it "redirects to results" do
          post :create

          expect(response).to redirect_to("/processes/#{component.participatory_space.slug}/f/#{component.id}/results")
        end
      end
    end
  end

  def do_request
    instance_eval(&perform_request)
  end
end
