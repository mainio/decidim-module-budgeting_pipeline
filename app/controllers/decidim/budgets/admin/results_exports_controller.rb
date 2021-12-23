# frozen_string_literal: true

module Decidim
  module Budgets
    module Admin
      class ResultsExportsController < Admin::ApplicationController
        def permission_class_chain
          [Decidim::BudgetingPipeline::Admin::Permissions] + super
        end

        def new
          enforce_permission_to :export_results, :budgets

          @form = form(Admin::ProjectExportResultsForm).from_model(
            current_component
          )
        end

        def create
          enforce_permission_to :export_results, :budgets

          @form = form(Admin::ProjectExportResultsForm).from_params(params)
          Admin::ExportProjectsToAccountability.call(@form) do
            on(:ok) do |results|
              flash[:notice] = I18n.t("results_exports.create.success", scope: "decidim.budgets.admin", number: results.length)
              redirect_to EngineRouter.admin_proxy(current_component).root_path
            end

            on(:invalid) do
              flash[:alert] = I18n.t("results_exports.create.invalid", scope: "decidim.budgets.admin")
              render action: "new"
            end
          end
        end
      end
    end
  end
end
