# frozen_string_literal: true

require_relative "budgeting_pipeline/version"
require_relative "budgeting_pipeline/engine"
require_relative "budgeting_pipeline/admin"
require_relative "budgeting_pipeline/admin_engine"

module Decidim
  module BudgetingPipeline
    autoload :HelpContainer, "decidim/budgeting_pipeline/help_container"

    include ActiveSupport::Configurable

    # This controls which sign in options are shown to user when starting the
    # voting process. The sign in options can be different than those shown on
    # the sign in page as voting generally requires an authorized user.
    config_accessor :identity_providers do
      ->(organization) { organization.enabled_omniauth_providers.keys }
    end

    config_accessor :identity_provider_name do
      ->(provider) { I18n.t("devise.shared.links.sign_in_with_provider", provider: provider.to_s.split("_").first.titleize) }
    end

    # This controls which authorization options are shown to signed in users
    # when starting the voting process in case they are already signed in but
    # not yet authorized.
    config_accessor :authorization_providers do
      ->(organization) { organization.available_authorizations }
    end

    config_accessor :authorization_provider_name do
      ->(provider) { I18n.t("#{provider}.name", scope: "decidim.authorization_handlers") }
    end
  end
end
