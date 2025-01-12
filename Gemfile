# frozen_string_literal: true

source "https://rubygems.org"

ruby RUBY_VERSION

# Inside the development app, the relative require has to be one level up, as
# the Gemfile is copied to the development_app folder (almost) as is.
base_path = ""
base_path = "../" if File.basename(__dir__) == "development_app"
require_relative "#{base_path}lib/decidim/budgeting_pipeline/version"

DECIDIM_VERSION = Decidim::BudgetingPipeline.decidim_version

gem "decidim", DECIDIM_VERSION
gem "decidim-budgeting_pipeline", path: "."

gem "decidim-favorites", github: "mainio/decidim-module-favorites", branch: "release/0.27-stable"
gem "decidim-stats", github: "mainio/decidim-module-stats", branch: "release/0.27-stable"

gem "bootsnap", "~> 1.4"
gem "puma", ">= 5.6.2"

gem "faker", "~> 2.14"

group :development, :test do
  gem "byebug", "~> 11.0", platform: :mri
  gem "decidim-dev", DECIDIM_VERSION
end

group :development do
  gem "letter_opener_web", "~> 2.0"
  gem "listen", "~> 3.1"
  gem "rubocop-faker"
  gem "spring", "~> 2.0"
  gem "spring-watcher-listen", "~> 2.0"
  gem "web-console", "~> 4.2"
end

group :test do
  gem "decidim-accountability", DECIDIM_VERSION
  gem "decidim-proposals", DECIDIM_VERSION

  gem "decidim-feedback", github: "mainio/decidim-module-feedback", branch: "release/0.27-stable"
  gem "decidim-ideas", github: "mainio/decidim-module-ideas", branch: "release/0.27-stable"
  gem "decidim-plans", github: "mainio/decidim-module-plans", branch: "release/0.27-stable"
  gem "decidim-tags", github: "mainio/decidim-module-tags", branch: "release/0.27-stable"
end
