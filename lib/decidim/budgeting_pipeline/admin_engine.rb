# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    # This is the engine that adds extra functionality to `decidim-budgets`
    # admin section.
    class AdminEngine < ::Rails::Engine
      isolate_namespace Decidim::BudgetingPipeline::Admin

      paths["db/migrate"] = nil
      paths["lib/tasks"] = nil

      initializer "decidim_budgeting_pipeline.admin_mount_routes" do
        Decidim::Budgets::AdminEngine.routes do
          resources :helps, param: :key, only: [:index] do
            resources :sections, controller: :help_sections, exclude: [:show]
          end
        end
      end

      initializer "decidim_budgeting_pipeline.extra_admin_routes", before: :add_routing_paths do
        # Mount the extra admin routes to Decidim::Admin::Engine because
        # otherwise they get mounted under the component itself. We need these
        # specific routes at the admin level.
        Decidim::Admin::Engine.routes.prepend do
          resources :projects_component_settings, only: [] do
            member do
              get :area_coordinates
            end
          end
        end
      end

      def load_seed
        nil
      end
    end
  end
end
