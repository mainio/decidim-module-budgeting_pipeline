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

      def display_more_information?
        translated_attribute(component_settings.more_information_modal).present?
      end

      def invalid_authorization_title
        translated_attribute(component_settings.vote_identify_invalid_authorization_title)
      end

      def invalid_authorization_content
        translated_attribute(component_settings.vote_identify_invalid_authorization_content)
      end

      def more_information_label
        label = translated_attribute(component_settings.more_information_modal_label)
        return label if label.present?

        t("decidim.budgets.votes.budgets.show_more_information_default")
      end

      def voting_step_link(step)
        attributes = { class: "step-selector" }
        attributes[:aria] = { current: "step" } if step.key == current_step

        link_to step.link, attributes do
          yield
        end
      end

      # This is for the projects view that displays the project filters that
      # refers the `budgets` variable.
      def budgets
        selected_budgets
      end

      def pipeline_header_hero
        wrapper_class = %w(voting-header__hero)
        style = nil

        if Decidim::BudgetingPipeline.pipeline_header_background_image
          bgval = "url(#{asset_path(Decidim::BudgetingPipeline.pipeline_header_background_image)})"
          style = "background-image:#{bgval}"
        else
          wrapper_class << "without-bg"
        end

        content_tag :div, class: wrapper_class.join(" "), style: style do
          yield
        end
      end
    end
  end
end
