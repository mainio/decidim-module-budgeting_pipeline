# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Budgets
    describe ProjectsHelper do
      include Decidim::LayoutHelper
      include Decidim::BudgetingPipeline::ProjectsHelperExtensions

      let!(:organization) { create(:organization) }
      let!(:budgets_component) { create(:budgets_component, :with_geocoding_enabled, organization:) }
      let(:budgets) { create_list(:budget, 2, component: budgets_component) }
      let!(:user) { create(:user, organization:) }
      let!(:projects) { create_list(:project, 5, budget: budgets.first, address:, latitude:, longitude:, component: budgets_component) }
      let!(:project) { projects.first }
      let(:address) { "Carrer Pic de Peguera 15, 17003 Girona" }
      let(:latitude) { 40.1234 }
      let(:longitude) { 2.1234 }

      before do
        allow(helper).to receive(:current_participatory_space).and_return(budgets_component.participatory_space)
        allow(helper).to receive(:current_component).and_return(budgets_component)
        allow(helper).to receive(:current_organization).and_return(organization)
        allow(helper).to receive(:budgets).and_return(budgets)
      end

      describe "#filter_budgets_label" do
        subject { helper.filter_budgets_label }

        it "returns correct translation" do
          expect(subject).to eq("Both areas")
        end
      end

      describe "#filter_activity_values" do
        subject { helper.filter_activity_values }

        it "returns correct translation" do
          expect(subject).to eq([%w(All all), ["My favorites", "favorites"]])
        end
      end

      describe "#projects_data_for_map" do
        subject { helper.projects_data_for_map(geocoded_projects_data) }

        before do
          allow(helper).to receive(:project_path).and_return("/budgets/projects/1")
        end

        context "when body is present" do
          let(:geocoded_projects_data) do
            [[1, "Project Title", "Short body text", "<h1>Heading</h1><p>Description</p>", address, latitude, longitude]]
          end

          it "uses the body field directly" do
            expect(subject.first[:body]).to eq("Short body text")
          end

          it "maps id, title, address, latitude, longitude" do
            result = subject.first
            expect(result[:id]).to eq(1)
            expect(result[:title]).to eq("Project Title")
            expect(result[:address]).to eq(address)
            expect(result[:latitude]).to eq(latitude)
            expect(result[:longitude]).to eq(longitude)
          end
        end

        context "when body is blank" do
          let(:geocoded_projects_data) do
            [[1, "Project Title", nil, "<h1>Heading</h1><p>Some long description text here</p>", address, latitude, longitude]]
          end

          it "falls back to the description field, stripping headings and tags" do
            expect(subject.first[:body]).not_to include("<h1>")
            expect(subject.first[:body]).not_to include("Heading")
            expect(subject.first[:body]).to include("Some long description text here")
          end

          it "truncates the body to 100 characters" do
            long_text = "A" * 200
            data = [[1, "Title", "", "<p>#{long_text}</p>", address, latitude, longitude]]
            result = helper.projects_data_for_map(data)
            expect(result.first[:body].length).to be <= 103 # 100 + ellipsis
          end
        end
      end

      describe "#identity_providers" do
        context "when identity_providers is a plain value" do
          before do
            allow(Decidim::BudgetingPipeline).to receive(:identity_providers).and_return([:foo, :bar])
          end

          it "returns the value directly" do
            expect(helper.identity_providers).to eq([:foo, :bar])
          end
        end

        context "when identity_providers is callable" do
          before do
            allow(Decidim::BudgetingPipeline).to receive(:identity_providers).and_return(
              ->(org) { org == organization ? [:provider_a] : [] }
            )
          end

          it "calls the lambda with the current organization" do
            expect(helper.identity_providers).to eq([:provider_a])
          end
        end
      end

      describe "#landing_page_content" do
        let(:current_settings) { double }
        let(:component_settings) { double }

        before do
          allow(helper).to receive(:current_settings).and_return(current_settings)
          allow(helper).to receive(:component_settings).and_return(component_settings)
        end

        context "when current_settings has landing_page_content" do
          before do
            allow(current_settings).to receive(:landing_page_content).and_return({ "en" => "Current content" })
            allow(component_settings).to receive(:landing_page_content).and_return({ "en" => "Default content" })
          end

          it "returns the current settings content" do
            expect(helper.landing_page_content).to eq("Current content")
          end
        end

        context "when current_settings content is blank" do
          before do
            allow(current_settings).to receive(:landing_page_content).and_return({ "en" => "" })
            allow(component_settings).to receive(:landing_page_content).and_return({ "en" => "Default content" })
          end

          it "falls back to component settings content" do
            expect(helper.landing_page_content).to eq("Default content")
          end
        end
      end

      describe "#display_budgets_filter?" do
        subject { helper.display_budgets_filter? }

        context "when there are multiple budgets" do
          it { is_expected.to be(true) }
        end

        context "when there is only one budget" do
          before { allow(helper).to receive(:budgets).and_return([budgets.first]) }

          it { is_expected.to be(false) }
        end
      end

      describe "#display_status_filter?" do
        subject { helper.display_status_filter? }

        let(:current_settings) { double }

        before do
          allow(helper).to receive(:current_settings).and_return(current_settings)
        end

        context "when voting is finished and show_selected_status is enabled" do
          before do
            allow(helper).to receive(:voting_finished?).and_return(true)
            allow(current_settings).to receive(:show_selected_status?).and_return(true)
          end

          it { is_expected.to be(true) }
        end

        context "when voting is not finished" do
          before do
            allow(helper).to receive(:voting_finished?).and_return(false)
            allow(current_settings).to receive(:show_selected_status?).and_return(true)
          end

          it { is_expected.to be(false) }
        end

        context "when show_selected_status is disabled" do
          before do
            allow(helper).to receive(:voting_finished?).and_return(true)
            allow(current_settings).to receive(:show_selected_status?).and_return(false)
          end

          it { is_expected.to be(false) }
        end
      end

      describe "#display_taxonomy_filter?" do
        subject { helper.display_taxonomy_filter?(taxonomy_filter) }

        let(:taxonomy_filter) { double }

        context "when the filter has items" do
          before { allow(taxonomy_filter).to receive(:filter_items).and_return([double]) }

          it { is_expected.to be(true) }
        end

        context "when the filter has no items" do
          before { allow(taxonomy_filter).to receive(:filter_items).and_return([]) }

          it { is_expected.to be(false) }
        end
      end

      describe "#display_budget_amount_filters?" do
        subject { helper.display_budget_amount_filters? }

        context "when there is a positive max budget amount" do
          before do
            create(:project, budget: budgets.first, budget_amount: 10_000, component: budgets_component)
          end

          it { is_expected.to be(true) }
        end

        context "when all projects have zero budget amount" do
          before do
            Decidim::Budgets::Project.where(budget: budgets).update_all(budget_amount: 0) # rubocop:disable Rails/SkipsModelValidations
          end

          it { is_expected.to be(false) }
        end
      end

      describe "#taxonomy_image_path" do
        subject { helper.taxonomy_image_path(project) }

        context "when project has no taxonomies" do
          before { allow(project).to receive(:taxonomies).and_return([]) }

          it { is_expected.to be_nil }
        end

        context "when no taxonomy has an image attached" do
          let(:taxonomy) { double(respond_to?: false) }

          before { allow(project).to receive(:taxonomies).and_return([taxonomy]) }

          it { is_expected.to be_nil }
        end

        context "when a taxonomy has an image attached" do
          let(:uploader) { double(variant_url: "/uploads/taxonomy_image.jpg") }
          let(:taxonomy) do
            double(
              respond_to?: true,
              taxonomy_image: double(attached?: true),
              attached_uploader: uploader
            )
          end

          before { allow(project).to receive(:taxonomies).and_return([taxonomy]) }

          it "returns the variant URL" do
            expect(subject).to eq("/uploads/taxonomy_image.jpg")
          end
        end
      end

      describe "#has_project_image?" do
        subject { helper.has_project_image? }

        before { allow(helper).to receive(:project).and_return(project) }

        context "when main_image is attached" do
          before do
            allow(project).to receive(:main_image).and_return(double(attached?: true))
          end

          it { is_expected.to be(true) }
        end

        context "when main_image is not attached" do
          before do
            allow(project).to receive(:main_image).and_return(double(attached?: false))
          end

          it { is_expected.to be(false) }
        end

        context "when main_image is nil" do
          before { allow(project).to receive(:main_image).and_return(nil) }

          it { is_expected.to be_falsey }
        end
      end

      describe "#share_image_url" do
        subject { helper.share_image_url }

        before { allow(helper).to receive(:project).and_return(project) }

        context "when the project has a main image" do
          let(:uploader) { double(url: "/uploads/project_image.jpg") }

          before do
            allow(helper).to receive(:has_project_image?).and_return(true)
            allow(project).to receive(:attached_uploader).with(:main_image).and_return(uploader)
          end

          it "returns the project image URL" do
            expect(subject).to eq("/uploads/project_image.jpg")
          end
        end

        context "when the project has no main image" do
          before do
            allow(helper).to receive(:has_project_image?).and_return(false)
            allow(helper).to receive(:organization_share_image_url).and_return("/uploads/org_image.jpg")
          end

          it "falls back to the organization share image" do
            expect(subject).to eq("/uploads/org_image.jpg")
          end
        end
      end

      describe "#project_taxonomy_names" do
        subject { helper.project_taxonomy_names(project) }

        let(:taxonomy_a) { double(name: { "en" => "Parks" }) }
        let(:taxonomy_b) { double(name: { "en" => "Transport" }) }

        before { allow(project).to receive(:taxonomies).and_return([taxonomy_a, taxonomy_b]) }

        it "returns taxonomy names joined by a comma" do
          expect(subject).to eq("Parks, Transport")
        end

        context "when the project has no taxonomies" do
          before { allow(project).to receive(:taxonomies).and_return([]) }

          it { is_expected.to eq("") }
        end
      end
    end
  end
end
