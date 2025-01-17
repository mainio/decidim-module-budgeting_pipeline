# frozen_string_literal: true

require "spec_helper"
require "decidim/api/test/type_context"

describe Decidim::BudgetingPipeline::BudgetMutationType do
  include_context "with a graphql class type"

  let(:model) { create(:budgeting_pipeline_budget, component:) }
  let(:participatory_space) { create(:participatory_process, organization: current_organization) }
  let(:component) { create(:budgeting_pipeline_component, participatory_space:) }

  let(:category) { create(:category, participatory_space:) }
  let(:scope) { create(:scope, organization: current_organization) }

  let(:proposals) { create_list(:proposal, 3, component: proposals_component) }
  let(:proposals_component) { create(:proposal_component, participatory_space:) }
  let(:ideas) { create_list(:idea, 2, component: ideas_component) }
  let(:ideas_component) { create(:idea_component, participatory_space:) }
  let(:plans) { create_list(:plan, 3, component: plans_component) }
  let(:plans_component) { create(:plan_component, participatory_space:) }

  describe "createProject" do
    let(:query) { "{ createProject(attributes: #{attributes_to_graphql(attributes)}) { id } }" }
    let(:attributes) do
      {
        title: { en: "New project" },
        summary: { en: "Project summary" },
        description: { en: "<p>Project description</p>" },
        budgetAmount: 50_000,
        budgetAmountMin: 20_000,
        location: {
          address: "Veneentekijäntie 4, Helsinki, Finland",
          latitude: 60.149792,
          longitude: 24.887430
        },
        categoryId: category.id,
        scopeId: scope.id,
        proposalIds: proposals.map(&:id),
        ideaIds: ideas.map(&:id),
        planIds: plans.map(&:id)
      }
    end

    context "with no user" do
      let!(:current_user) { nil }

      it "does not allow creating the project" do
        expect { response }.to raise_error(Decidim::BudgetingPipeline::ActionForbidden)
      end
    end

    context "with a participant user" do
      it "does not allow creating the project" do
        expect { response }.to raise_error(Decidim::BudgetingPipeline::ActionForbidden)
      end
    end

    context "with an admin user" do
      let!(:current_user) { create(:user, :confirmed, :admin, organization: current_organization) }

      it "creates the project" do
        expect { response }.to change(Decidim::Budgets::Project, :count).by(1)

        project = Decidim::Budgets::Project.order(:id).last
        expect(response["createProject"]).to eq("id" => project.id.to_s)

        expect(project.title).to match(attributes[:title].stringify_keys)
        expect(project.summary).to match(attributes[:summary].stringify_keys)
        expect(project.description).to match(attributes[:description].stringify_keys)
        expect(project.budget_amount).to eq(attributes[:budgetAmount])
        expect(project.budget_amount_min).to eq(attributes[:budgetAmountMin])
        expect(project.address).to eq(attributes[:location][:address])
        expect(project.latitude).to eq(attributes[:location][:latitude])
        expect(project.longitude).to eq(attributes[:location][:longitude])
        expect(project.category.id).to eq(category.id)
        expect(project.scope.id).to eq(scope.id)
        expect(project.linked_resources(:proposals, "included_proposals").map(&:id)).to match_array(proposals.map(&:id))
        expect(project.linked_resources(:ideas, "included_ideas").map(&:id)).to match_array(ideas.map(&:id))
        expect(project.linked_resources(:plans, "included_plans").map(&:id)).to match_array(plans.map(&:id))

        expect(project.selected?).to be(false)
      end

      context "with a blob" do
        let(:blob) do
          ActiveStorage::Blob.create_and_upload!(
            io: File.open(Decidim::Dev.asset("city.jpeg")),
            filename: "city.jpeg",
            content_type: "image/jpeg"
          )
        end
        let(:attributes) do
          {
            title: { en: "New project" },
            summary: { en: "Project summary" },
            description: { en: "<p>Project description</p>" },
            budgetAmount: 50_000,
            mainImage: { blobId: blob.id }
          }
        end

        let(:query) { "{ createProject(attributes: #{attributes_to_graphql(attributes)}) { id } }" }

        it "adds the project image" do
          expect { response }.to change(Decidim::Budgets::Project, :count).by(1)

          project = Decidim::Budgets::Project.order(:id).last
          expect(response["createProject"]).to eq("id" => project.id.to_s)

          expect(project.main_image.blob).to eq(blob)
        end
      end
    end
  end

  describe "updateProject" do
    let!(:project) { create(:budgeting_pipeline_project, budget: model) }
    let(:query) { "{ updateProject(id: #{project.id}, attributes: #{attributes_to_graphql(attributes)}) { id } }" }
    let(:attributes) do
      {
        title: { en: "Updated project" },
        summary: { en: "Project summary" },
        description: { en: "<p>Project description</p>" },
        budgetAmount: 50_000,
        budgetAmountMin: 20_000,
        location: {
          address: "Veneentekijäntie 4, Helsinki, Finland",
          latitude: 60.149792,
          longitude: 24.887430
        },
        categoryId: category.id,
        scopeId: scope.id,
        proposalIds: proposals.map(&:id),
        ideaIds: ideas.map(&:id),
        planIds: plans.map(&:id)
      }
    end

    context "with no user" do
      let!(:current_user) { nil }

      it "does not allow updating the project" do
        expect { response }.to raise_error(Decidim::BudgetingPipeline::ActionForbidden)
      end
    end

    context "with a participant user" do
      it "does not allow updating the project" do
        expect { response }.to raise_error(Decidim::BudgetingPipeline::ActionForbidden)
      end
    end

    context "with an admin user" do
      let!(:current_user) { create(:user, :confirmed, :admin, organization: current_organization) }

      it "updates the project" do
        expect { response }.not_to change(Decidim::Budgets::Project, :count)

        expect(response["updateProject"]).to eq("id" => project.id.to_s)
        project.reload

        expect(project.title["en"]).to match(attributes[:title][:en])
        expect(project.summary["en"]).to match(attributes[:summary][:en])
        expect(project.description["en"]).to match(attributes[:description][:en])
        expect(project.budget_amount).to eq(attributes[:budgetAmount])
        expect(project.budget_amount_min).to eq(attributes[:budgetAmountMin])
        expect(project.address).to eq(attributes[:location][:address])
        expect(project.latitude).to eq(attributes[:location][:latitude])
        expect(project.longitude).to eq(attributes[:location][:longitude])
        expect(project.category.id).to eq(category.id)
        expect(project.scope.id).to eq(scope.id)
        expect(project.linked_resources(:proposals, "included_proposals").map(&:id)).to match_array(proposals.map(&:id))
        expect(project.linked_resources(:ideas, "included_ideas").map(&:id)).to match_array(ideas.map(&:id))
        expect(project.linked_resources(:plans, "included_plans").map(&:id)).to match_array(plans.map(&:id))

        expect(project.selected?).to be(false)
      end

      context "when the project is selected" do
        before { project.update!(selected_at: Time.current) }

        it "does not change the selected state" do
          expect { response }.not_to change(Decidim::Budgets::Project, :count)

          expect(response["updateProject"]).to eq("id" => project.id.to_s)
          project.reload

          expect(project.selected?).to be(true)
        end
      end

      context "with a blob" do
        let(:blob) do
          ActiveStorage::Blob.create_and_upload!(
            io: File.open(Decidim::Dev.asset("city.jpeg")),
            filename: "city.jpeg",
            content_type: "image/jpeg"
          )
        end
        let(:attributes) do
          {
            title: { en: "Updated project" },
            summary: { en: "Project summary" },
            description: { en: "<p>Project description</p>" },
            budgetAmount: 50_000,
            mainImage: { blobId: blob.id }
          }
        end

        let(:query) { "{ updateProject(id: #{project.id}, attributes: #{attributes_to_graphql(attributes)}) { id } }" }

        it "updates the project image" do
          expect { response }.not_to change(Decidim::Budgets::Project, :count)

          expect(response["updateProject"]).to eq("id" => project.id.to_s)
          project.reload

          expect(project.main_image.blob).to eq(blob)
        end
      end
    end
  end

  describe "deleteProject" do
    let!(:project) { create(:budgeting_pipeline_project, budget: model) }
    let(:query) { "{ deleteProject(id: #{project.id}) { id } }" }

    context "with no user" do
      let!(:current_user) { nil }

      it "does not allow deleting the project" do
        expect do
          expect { response }.to raise_error(Decidim::BudgetingPipeline::ActionForbidden)
        end.not_to change(Decidim::Budgets::Project, :count)
      end
    end

    context "with a participant user" do
      it "does not allow deleting the project" do
        expect do
          expect { response }.to raise_error(Decidim::BudgetingPipeline::ActionForbidden)
        end.not_to change(Decidim::Budgets::Project, :count)
      end
    end

    context "with an admin user" do
      let!(:current_user) { create(:user, :confirmed, :admin, organization: current_organization) }

      it "deletes the project" do
        expect { response }.to change(Decidim::Budgets::Project, :count).by(-1)

        expect(response["deleteProject"]).to eq("id" => project.id.to_s)
      end
    end
  end

  def attributes_to_graphql(attributes)
    payload = attributes.map do |key, value|
      case value
      when Hash
        "#{key}: #{attributes_to_graphql(value)}"
      when Array, Integer, Float
        "#{key}: #{value.to_json}"
      when String
        %(#{key}: "#{value.gsub('"', '\"')}")
      end
    end

    "{ #{payload.join(", ")} }"
  end
end
