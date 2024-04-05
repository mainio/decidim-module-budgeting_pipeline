# frozen_string_literal: true

require "spec_helper"

describe Decidim::Budgets::Project do
  let(:component) { create(:budgeting_pipeline_component) }

  describe ".geocoded_data_for" do
    subject { geocoded_data }

    let(:geocoded_data) { described_class.order(:id).geocoded_data_for(component) }

    let(:data_mapping) { [:id, :title, :summary, :description, :address, :latitude, :longitude] }
    let(:data_mapping_translated) { [:title, :summary, :description] }

    let(:budget1) { create(:budgeting_pipeline_budget, component: component) }
    let(:budget2) { create(:budgeting_pipeline_budget, component: component) }
    let!(:budget1_projects) { create_list(:budgeting_pipeline_project, 10, budget: budget1) }
    let!(:budget2_projects) { create_list(:budgeting_pipeline_project, 5, budget: budget2) }
    let(:expected_data) do
      budget1_projects.map { |project| convert_project_data(project) } +
        budget2_projects.map { |project| convert_project_data(project) }
    end

    let(:component_coordinates) { component.settings.default_map_center_coordinates.split(",") }
    let(:default_latitude) { component_coordinates[0].to_f.round(12) }
    let(:default_longitude) { component_coordinates[1].to_f.round(12) }

    it "returns the correct amount of projects" do
      expect(subject.count).to eq(15)
    end

    it "returns the correct geocoded data" do
      expect(subject).to eq(expected_data)
    end

    describe "case statements" do
      subject { geocoded_data.first }

      let(:project) { create(:budgeting_pipeline_project, budget: budget1) }
      let!(:budget1_projects) { [project] }
      let!(:budget2_projects) { [] }

      context "when the locale is not the default locale" do
        let(:returned_data) do
          data_mapping_translated.index_with do |key|
            data_for_key(subject, key)
          end
        end

        around do |example|
          I18n.with_locale(:ca) { example.run }
        end

        it "returns the translatable data in the correct locale" do
          expect(returned_data[:title]).to eq(project.title["ca"])
          expect(returned_data[:summary]).to eq(project.summary["ca"])
          expect(returned_data[:description]).to eq(project.description["ca"])
        end

        context "when the locale does not have the translation defined" do
          let(:project) do
            create(
              :budgeting_pipeline_project,
              title: { en: "Title" },
              summary: { en: "Summary" },
              description: { en: "<p>Description</p>" },
              budget: budget1
            )
          end

          it "returns the translatable data in the default locale" do
            expect(returned_data[:title]).to eq(project.title["en"])
            expect(returned_data[:summary]).to eq(project.summary["en"])
            expect(returned_data[:description]).to eq(project.description["en"])
          end
        end
      end

      context "when the project does not have an address" do
        let(:project) { create(:budgeting_pipeline_project, budget: budget1, address: nil) }
        let(:returned_data) { data_for_key(subject, :address) }

        it "returns the budget title as address" do
          expect(returned_data).to eq(translated(budget1.title))
        end
      end

      context "when the project does not have a latitude" do
        let(:project) { create(:budgeting_pipeline_project, budget: budget1, latitude: nil) }
        let(:returned_data) { data_for_key(subject, :latitude) }

        it "returns the budget center latitude" do
          expect(returned_data).to eq(budget1.center_latitude)
        end

        context "and the budget does not have a center latitude" do
          let(:budget1) { create(:budgeting_pipeline_budget, component: component, center_latitude: nil) }

          it "returns the default latitude" do
            expect(returned_data).to eq(default_latitude)
          end
        end
      end

      context "when the project does not have a longitude" do
        let(:project) { create(:budgeting_pipeline_project, budget: budget1, longitude: nil) }
        let(:returned_data) { data_for_key(subject, :longitude) }

        it "returns the budget center longitude" do
          expect(returned_data).to eq(budget1.center_longitude)
        end

        context "and the budget does not have a center longitude" do
          let(:budget1) { create(:budgeting_pipeline_budget, component: component, center_longitude: nil) }

          it "returns the default longitude" do
            expect(returned_data).to eq(default_longitude)
          end
        end
      end
    end

    def convert_project_data(project)
      data_mapping.map do |key|
        if data_mapping_translated.include?(key)
          translated(project.public_send(key))
        else
          project.public_send(key)
        end
      end
    end

    def data_for_key(member, key)
      member[data_mapping.index(key)]
    end
  end

  describe ".order_by_most_voted" do
    subject { described_class.where(budget: budget).order_by_most_voted }

    let(:budget) { create(:budgeting_pipeline_budget, component: component) }
    let(:budget_projects) { create_list(:budgeting_pipeline_project, 5, budget: budget, paper_orders_count: 0) }
    let(:expected_order) { [1, 3, 2, 4, 0].map { |idx| budget_projects[idx] } }

    let!(:complete_votes) { [0, 11, 7, 9, 1] }
    let!(:incomplete_votes) { [12, 0, 3, 0, 7] }

    before do
      [:complete_votes, :incomplete_votes].each do |key|
        amounts = public_send(key)
        budget_projects.each_with_index do |project, idx|
          orders = create_list(:budgeting_pipeline_order, amounts[idx], budget: budget)
          orders.each do |order|
            order.projects << project
            order.checked_out_at = Time.current if key == :complete_votes
            order.save!
          end
        end
      end
    end

    it "returns the projects in correct order" do
      expect(subject.map(&:id)).to eq(expected_order.map(&:id))
    end

    context "with only_voted set to true" do
      subject { described_class.where(budget: budget).order_by_most_voted(only_voted: true) }

      let(:expected_order) { [1, 3, 2, 4].map { |idx| budget_projects[idx] } }

      it "returns only the projects which have votes" do
        expect(subject.map(&:id)).to eq(expected_order.map(&:id))
      end
    end

    context "with paper ballots" do
      let(:expected_order) { [4, 3, 2, 1, 0].map { |idx| budget_projects[idx] } }

      before do
        amounts = [111, 222, 333, 444, 555]
        budget_projects.each_with_index do |project, idx|
          project.update!(paper_orders_count: amounts[idx])
        end
      end

      it "returns the projects in correct order" do
        expect(subject.map(&:id)).to eq(expected_order.map(&:id))
      end
    end

    context "with favorites filtering" do
      subject { described_class.where(budget: budget).user_favorites(user).order_by_most_voted }

      let(:user) { create(:user, :confirmed, organization: component.organization) }
      let(:favorite_projects) { budget_projects[0..1] }
      let!(:favorites) { favorite_projects.map { |pr| create(:favorite, favoritable: pr, user: user) } }

      it "returns the favorites" do
        expect(subject).to match_array(favorite_projects)
      end
    end
  end

  describe "#confirmed_orders_count" do
    subject { project.confirmed_orders_count }

    let(:budget) { create(:budgeting_pipeline_budget, component: component) }
    let(:project) { create(:budgeting_pipeline_project, budget: budget, paper_orders_count: paper_orders_count) }
    let(:paper_orders_count) { 0 }

    let!(:complete_votes) { 123 }
    let!(:incomplete_votes) { 7 }

    before do
      [:complete_votes, :incomplete_votes].each do |key|
        amount = public_send(key)
        orders = create_list(:budgeting_pipeline_order, amount, budget: budget)
        orders.each do |order|
          order.projects << project
          order.checked_out_at = Time.current if key == :complete_votes
          order.save!
        end
      end
    end

    it "returns the completed orders count" do
      expect(subject).to eq(complete_votes)
    end

    context "with paper ballots" do
      let(:paper_orders_count) { 62 }

      it "returns the completed orders count with the paper ballots added to it" do
        expect(subject).to eq(complete_votes + paper_orders_count)
      end
    end
  end
end
