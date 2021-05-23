# frozen_string_literal: true

module Decidim
  module Budgets
    module VotesHelper
      include Decidim::BudgetingPipeline::ProjectsHelperExtensions

      def identity_providers
        providers = Decidim::BudgetingPipeline.identity_providers
        return providers unless providers.respond_to?(:call)

        providers.call(current_organization)
      end

      def identity_provider_name(provider)
        Decidim::BudgetingPipeline.identity_provider_name.call(provider)
      end

      def authorization_providers
        providers = Decidim::BudgetingPipeline.authorization_providers
        providers = providers.call(current_organization) if providers.respond_to?(:call)

        Verifications::Adapter.from_collection(
          providers - Decidim::Authorization.where(user: current_user).where.not(
            granted_at: nil
          ).pluck(:name)
        )
      end

      def authorization_provider_name(provider)
        Decidim::BudgetingPipeline.authorization_provider_name.call(provider)
      end

      # This is for the projects view that displays the budget selector.
      def budgets
        selected_budgets
      end
    end
  end
end
