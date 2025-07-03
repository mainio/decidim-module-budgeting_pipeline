# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    module AuthorizationHelper
      include Decidim::BudgetingPipeline::ProjectsHelperExtensions
      include Decidim::BudgetingPipeline::ProjectItemUtilities
      include Decidim::BudgetingPipeline::TextUtilities

      def available_authorization_provider_keys
        providers = Decidim::BudgetingPipeline.authorization_providers
        providers = providers.call(current_organization) if providers.respond_to?(:call)
        providers
      end

      def authorization_providers
        Verifications::Adapter.from_collection(
          available_authorization_provider_keys - user_authorizations.pluck(:name)
        )
      end

      def user_authorizations(type = :all)
        base = Decidim::Authorization.where(
          name: available_authorization_provider_keys,
          user: current_user
        )
        return base.where.not(granted_at: nil) if type == :granted
        return base.where(granted_at: nil) if type == :pending

        base
      end

      def authorization_provider_name(provider)
        Decidim::BudgetingPipeline.authorization_provider_name.call(provider)
      end

      def invalid_authorization_title
        translated_attribute(component_settings.vote_identify_invalid_authorization_title)
      end

      def invalid_authorization_content
        translated_attribute(component_settings.vote_identify_invalid_authorization_content)
      end

      # This is for the projects view that displays the project filters that
      # refers the `budgets` variable.
      def budgets
        selected_budgets
      end
    end
  end
end
