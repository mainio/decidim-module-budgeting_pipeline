# frozen_string_literal: true

require "spec_helper"

module Decidim::Budgets
  describe Admin::UpdateProject do
    include Decidim::BudgetingPipeline::AdminUpdateProjectExtensions
    subject { described_class.new(form, project) }

    let!(:project) { create(:project, budget:) }
    let(:organization) { create(:organization, available_locales: [:en]) }
    let(:current_user) { create(:user, :admin, :confirmed, organization:) }
    let(:participatory_process) { create(:participatory_process, organization:) }
    let(:current_component) { create(:component, manifest_name: :budgets, participatory_space: participatory_process) }
    let(:budget) { create(:budget, component: current_component) }
    let(:scope) { create(:scope, organization:) }
    let(:category) { create(:category, participatory_space: participatory_process) }
    let(:uploaded_photos) { [] }
    let(:main_image) { nil }
    let(:photos) { [] }
    let(:address) { nil }
    let(:latitude) { 40.1234 }
    let(:longitude) { 2.1234 }
    let(:selected) { true }
    let(:proposal_component) do
      create(:component, manifest_name: :proposals, participatory_space: participatory_process)
    end
    let(:proposals) do
      create_list(
        :proposal,
        3,
        component: proposal_component
      )
    end
    let(:form) do
      double(
        invalid?: invalid,
        current_component:,
        current_user:,
        title: { en: "title" },
        summary: { en: "Summary for the project" },
        description: { en: "description" },
        budget_amount: 10_000_000,
        budget_amount_min: nil,
        address:,
        latitude:,
        longitude:,
        proposal_ids: proposals.map(&:id),
        selected:,
        scope:,
        category:,
        photos:,
        add_photos: uploaded_photos,
        budget:,
        idea_ids:,
        plan_ids:,
        main_image:
      )
    end
    let(:idea_ids) { [] }
    let(:plan_ids) { [] }
    let(:invalid) { false }

    context "when everything is ok" do
      it "sets the scope" do
        subject.call
        expect(project.scope).to eq scope
      end

      it "sets the category" do
        subject.call
        expect(project.category).to eq category
      end

      it "sets the budget resource" do
        subject.call
        expect(project.budget).to eq budget
      end

      it "sets the budget summary" do
        subject.call
        expect(project.summary).to eq({ "en" => "Summary for the project" })
      end

      it "traces the action", versioning: true do
        expect(Decidim.traceability)
          .to receive(:update!)
          .with(
            project,
            current_user,
            hash_including(:scope, :category, :title, :summary, :description, :budget_amount, :selected_at, :address, :latitude, :longitude)
          )
          .and_call_original

        expect { subject.call }.to change(Decidim::ActionLog, :count)
        action_log = Decidim::ActionLog.last
        expect(action_log.version).to be_present
      end

      context "when geocoding is enabled" do
        let(:current_component) { create(:budgets_component, :with_geocoding_enabled, participatory_space: participatory_process) }

        context "when the address is present" do
          let(:address) { "Some address" }

          before do
            stub_geocoding(address, [latitude, longitude])
          end

          it "sets the latitude and longitude" do
            subject.call
            project = Decidim::Budgets::Project.last

            expect(project.latitude).to eq(latitude)
            expect(project.longitude).to eq(longitude)
          end
        end
      end

      context "with ideas" do
        let(:idea_component) { create(:idea_component, participatory_space: participatory_process) }
        let(:idea1) { create(:idea, component: idea_component) }
        let(:idea_ids) { [idea1.id] }

        it "links ideas" do
          subject.call

          project = Decidim::Budgets::Project.last
          linked_ideas = project.linked_resources(:ideas, "included_ideas")

          expect(linked_ideas).to contain_exactly(idea1)
        end
      end

      context "with plans" do
        let(:plan_component) { create(:plan_component, participatory_space: participatory_process) }
        let(:plan1) { create(:plan, component: plan_component) }
        let(:plan_ids) { [plan1.id] }

        it "links plans" do
          subject.call

          project = Decidim::Budgets::Project.last
          linked_plans = project.linked_resources(:plans, "included_plans")

          expect(linked_plans).to contain_exactly(plan1)
        end
      end
    end
  end
end
