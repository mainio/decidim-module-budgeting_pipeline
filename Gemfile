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

gem "decidim-apifiles", github: "mainio/decidim-module-apifiles", branch: "release/0.28-stable"
gem "decidim-favorites", github: "mainio/decidim-module-favorites", branch: "release/0.28-stable"
gem "decidim-feedback", github: "mainio/decidim-module-feedback", branch: "release/0.28-stable"
gem "decidim-stats", github: "mainio/decidim-module-stats", branch: "release/0.28-stable"

gem "bootsnap", "~> 1.4"

# This is a temporary fix for: https://github.com/rails/rails/issues/54263

gem "puma", ">= 6.4.2"

group :development, :test do
  gem "byebug", "~> 11.0", platform: :mri
  gem "decidim-dev", DECIDIM_VERSION
end

group :development do
  gem "faker", "~> 3.2.2"
  gem "letter_opener_web", "~> 2.0"
  gem "listen", "~> 3.8"
  gem "web-console", "~> 4.2"

  # rubocop & rubocop-rspec are set to the following versions because of a change where FactoryBot/CreateList
  # must be a boolean instead of contextual. These version locks can be removed when this problem is handled
  # through decidim-dev.
  # gem "rubocop", "~>1.28"
  # gem "rubocop-faker"
  # gem "rubocop-rspec", "2.20"

  # gem "spring", "~> 4.1.3"
  # gem "spring-watcher-listen", "~> 2.1"
end

group :test do
  gem "decidim-accountability", DECIDIM_VERSION
  gem "decidim-proposals", DECIDIM_VERSION

  gem "decidim-ideas", github: "mainio/decidim-module-ideas", branch: "release/0.28-stable"
  gem "decidim-plans", github: "mainio/decidim-module-plans", branch: "release/0.28-stable"
  gem "decidim-tags", github: "mainio/decidim-module-tags", branch: "release/0.28-stable"
end
