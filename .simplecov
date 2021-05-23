# frozen_string_literal: true

SimpleCov.start do
  root ENV["ENGINE_ROOT"]

  add_filter "lib/decidim/budgeting_pipeline/version.rb"
  add_filter "lib/decidim/budgeting_pipeline/generators"
  add_filter "/spec"
end

SimpleCov.command_name ENV["COMMAND_NAME"] || File.basename(Dir.pwd)

SimpleCov.merge_timeout 1800
