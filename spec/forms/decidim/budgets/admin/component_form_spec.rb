# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Budgets
    module Admin
      describe ComponentForm do
        include ::Decidim::BudgetingPipeline::AdminComponentFormExtensions
        subject { form }

        let(:organization) { create(:organization) }
        let(:participatory_space) { create(:participatory_process, organization: organization) }
        let(:manifest) { Decidim.find_component_manifest("dummy") }
        let(:name) { generate_localized_title }

        let(:dummy_global_translatable_text) do
          {
            "dummy_global_translatable_text_ca" => "",
            "dummy_global_translatable_text_en" => "Dummy text en",
            "dummy_global_translatable_text_es" => ""
          }
        end

        let(:dummy_step_translatable_text) do
          {
            "dummy_step_translatable_text_ca" => "",
            "dummy_step_translatable_text_en" => "Dummy text en",
            "dummy_step_translatable_text_es" => ""
          }
        end

        let(:settings) do
          return {} unless manifest

          manifest.settings(:global).schema.new(dummy_global_translatable_text, "en")
        end

        let(:default_step_settings) do
          return {} unless manifest

          manifest.settings(:step).schema.new(dummy_step_translatable_text, "en")
        end

        let(:params) do
          {
            "name" => name,
            "manifest" => manifest,
            "participatory_space" => participatory_space,
            "settings" => settings,
            "default_step_settings" => default_step_settings
          }
        end

        let(:form) do
          described_class.from_params(params).with_context(current_organization: organization)
        end

        context "when everything is ok" do
          it { is_expected.to be_valid }
        end

        describe "#budget_voting_rule_minimum_value_setting" do
          context "when manifest name is not budget" do
            it { is_expected.to be_valid }
          end

          context "when manifest is budgets" do
            let(:manifest) { Decidim.find_component_manifest("budgets") }

            context "when vote_rule_minimum_budget_projects is disable" do
              it { is_expected.to be_valid }
            end

            context "when vote_rule_minimum_budget_projects is enabled" do
              before do
                allow(settings).to receive(:vote_rule_minimum_budget_projects_enabled).and_return(true)
              end

              context "when vote_minimum_budget_projects_number is blank" do
                before do
                  allow(settings).to receive(:vote_minimum_budget_projects_number).and_return(nil)
                end

                it { is_expected.not_to be_valid }
              end

              context "when vote_minimum_budget_projects_number is negative" do
                before do
                  allow(settings).to receive(:vote_minimum_budget_projects_number).and_return(-1)
                end

                it { is_expected.not_to be_valid }
              end
            end
          end
        end
      end
    end
  end
end
