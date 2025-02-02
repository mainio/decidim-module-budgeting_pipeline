# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    class BudgetMutationType < GraphQL::Schema::Object
      include Decidim::BudgetingPipeline::Api::Permissions

      graphql_name "BudgetMutation"
      description "A budget which includes its available mutations"

      field :id, GraphQL::Types::ID, "The Budget's unique ID", null: false

      field :create_project, Decidim::Budgets::ProjectType, null: false do
        description "A mutation to create a project within a budget."

        argument :attributes, ProjectAttributes, required: true
      end

      field :update_project, Decidim::Budgets::ProjectType, null: true do
        description "A mutation to update a project within a budget."

        argument :id, GraphQL::Types::ID, required: true
        argument :attributes, ProjectAttributes, required: true
      end

      field :delete_project, Decidim::Budgets::ProjectType, null: true do
        description "A mutation to delete a project within a budget."

        argument :id, GraphQL::Types::ID, required: true
      end

      def create_project(attributes:)
        enforce_permission_to :create, :project

        form = project_form_from(attributes)

        Decidim::Budgets::Admin::CreateProject.call(form) do
          on(:ok) do
            # The command does not broadcast the project so we need to fetch it
            # from a private method within the command itself.
            return project
          end
          on(:invalid) do
            return GraphQL::ExecutionError.new(
              form.errors.full_messages.join(", ")
            )
          end
        end

        GraphQL::ExecutionError.new(
          I18n.t("decidim.budgets.admin.projects.create.invalid")
        )
      end

      def update_project(id:, attributes:)
        project = object.projects.find_by(id:)
        return unless project

        enforce_permission_to(:update, :project, project:)

        form = project_form_from(attributes, project)
        Decidim::Budgets::Admin::UpdateProject.call(form, project) do
          on(:ok) do
            return project
          end
          on(:invalid) do
            return GraphQL::ExecutionError.new(
              form.errors.full_messages.join(", ")
            )
          end
        end

        GraphQL::ExecutionError.new(
          I18n.t("decidim.budgets.admin.projects.update.invalid")
        )
      end

      def delete_project(id:)
        project = object.projects.find_by(id:)
        return unless project

        enforce_permission_to(:destroy, :project, project:)

        Decidim::Budgets::Admin::DestroyProject.call(project, current_user) do
          on(:ok) do
            return project
          end
        end

        GraphQL::ExecutionError.new(
          I18n.t("decidim.budgets.admin.projects.destroy.invalid")
        )
      end

      private

      def project_form_from(attributes, project = nil)
        Decidim::Budgets::Admin::ProjectForm.from_params(
          "project" => project_params(attributes, project)
        ).with_context(
          current_organization:,
          current_component: object.component,
          current_user:,
          budget: object
        )
      end

      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def project_params(attributes, project = nil)
        {
          "title" => attributes.title,
          "summary" => attributes.summary,
          "description" => attributes.description,
          "budget_amount" => attributes.budget_amount,
          "budget_amount_min" => attributes.budget_amount_min,
          "address" => attributes&.location&.address,
          "latitude" => attributes&.location&.latitude,
          "longitude" => attributes&.location&.longitude,
          "decidim_category_id" => attributes.category_id,
          "decidim_scope_id" => attributes.scope_id,
          "proposal_ids" => attributes.proposal_ids || related_ids_for(project, :proposals),
          "idea_ids" => attributes.idea_ids || related_ids_for(project, :ideas),
          "plan_ids" => attributes.plan_ids || related_ids_for(project, :plans)
        }.tap do |attrs|
          attrs["selected"] ||= project&.selected?
          attrs.merge!(attributes.main_image_attributes) if attributes.main_image_attributes
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      def related_ids_for(project, resource)
        return [] unless project

        project.linked_resources(resource, "included_#{resource}").map(&:id)
      end

      def current_organization
        context[:current_organization]
      end

      def current_user
        context[:current_user]
      end
    end
  end
end
