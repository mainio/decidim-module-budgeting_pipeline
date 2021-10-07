# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "decidim/budgeting_pipeline/version"

Gem::Specification.new do |spec|
  spec.name = "decidim-budgeting_pipeline"
  spec.version = Decidim::BudgetingPipeline::VERSION
  spec.required_ruby_version = ">= 2.6"
  spec.authors = ["Antti Hukkanen"]
  spec.email = ["antti.hukkanen@mainiotech.fi"]

  spec.summary = "Budgeting pipeline for the budgets component."
  spec.description = "Provides a budgeting pipeline implementation for the core budgets component."
  spec.homepage = "https://github.com/mainio/decidim-module-budgeting_pipeline"
  spec.license = "AGPL-3.0"

  spec.files = Dir[
    "{app,config,lib}/**/*",
    "LICENSE-AGPLv3.txt",
    "Rakefile",
    "README.md"
  ]

  spec.require_paths = ["lib"]

  spec.add_dependency "decidim-budgets", Decidim::BudgetingPipeline::DECIDIM_VERSION
  spec.add_dependency "decidim-core", Decidim::BudgetingPipeline::DECIDIM_VERSION
  spec.add_dependency "decidim-favorites", Decidim::BudgetingPipeline::DECIDIM_VERSION
  spec.add_dependency "decidim-stats", Decidim::BudgetingPipeline::DECIDIM_VERSION

  spec.add_development_dependency "decidim-dev", Decidim::BudgetingPipeline::DECIDIM_VERSION
end
