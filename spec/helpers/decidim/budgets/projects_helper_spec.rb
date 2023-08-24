# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Budgets
    describe ProjectsHelper do
      include Decidim::LayoutHelper
      include Decidim::BudgetingPipeline::ProjectsHelperExtensions

      let!(:organization) { create(:organization) }
      let!(:budgets_component) { create(:budgets_component, :with_geocoding_enabled, organization: organization) }
      let(:budgets) { create_list(:budget, 2, component: budgets_component) }
      let!(:user) { create(:user, organization: organization) }
      let!(:projects) { create_list(:project, 5, budget: budgets.first, address: address, latitude: latitude, longitude: longitude, component: budgets_component) }
      let!(:project) { projects.first }
      let(:address) { "Carrer Pic de Peguera 15, 17003 Girona" }
      let(:latitude) { 40.1234 }
      let(:longitude) { 2.1234 }

      before do
        allow(helper).to receive(:current_participatory_space).and_return(budgets_component.participatory_space)
        allow(helper).to receive(:current_component).and_return(budgets_component)
        allow(helper).to receive(:budgets).and_return(budgets)
      end

      describe "#filter_categories_values" do
        subject { helper.filter_categories_values }

        let!(:category) { create(:category, participatory_space: budgets_component.participatory_space) }

        it "returns values" do
          expect(subject).to eq([[translated(category.name), category.id]])
        end
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
    end
  end
end
