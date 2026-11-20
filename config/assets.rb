# frozen_string_literal: true

base_path = File.expand_path("..", __dir__)

# Register the additonal path for Shakapacker in order to make the module's
# stylesheets available for inclusion.
Decidim::Shakapacker.register_path("#{base_path}/app/packs")

# Register the entrypoints for your module. These entrypoints can be included
# within your application using `javascript_pack_tag` and if you include any
# SCSS files within the entrypoints, they become available for inclusion using
# `stylesheet_pack_tag`.
Decidim::Shakapacker.register_entrypoints(
  decidim_budgeting_pipeline: "#{base_path}/app/packs/entrypoints/decidim_budgeting_pipeline.js",
  decidim_budgeting_pipeline_budgets: "#{base_path}/app/packs/entrypoints/decidim_budgeting_pipeline_budgets.js",
  decidim_budgeting_pipeline_preview: "#{base_path}/app/packs/entrypoints/decidim_budgeting_pipeline_preview.js",
  decidim_budgeting_pipeline_projects: "#{base_path}/app/packs/entrypoints/decidim_budgeting_pipeline_projects.js",
  decidim_budgeting_pipeline_admin_projects: "#{base_path}/app/packs/entrypoints/decidim_budgeting_pipeline_admin_projects.js"
)

# Register the main application's stylesheet include statement
# Decidim::Shakapacker.register_stylesheet_import("stylesheets/decidim/budgeting_pipeline/budgets")
