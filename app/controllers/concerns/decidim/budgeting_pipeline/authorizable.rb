# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    module Authorizable
      extend ActiveSupport::Concern

      # This ensures that only people eligible to vote can enter the voting
      # pipeline after the authorization step. The authorization conditions
      # should be used to control user's ability to vote (e.g. where they live,
      # how old they are, etc.).
      def user_authorized?
        @user_authorized ||= user_signed_in? && action_authorized_to("vote").ok?
      end

      def authorization_required?
        @authorization_required ||= begin
          permission = current_component.permissions&.fetch("vote", nil)
          handlers = permission&.fetch("authorization_handlers", nil)&.keys
          if handlers && handlers.any?
            providers = Decidim::BudgetingPipeline.authorization_providers
            providers = providers.call(current_organization) if providers.respond_to?(:call)
            (handlers & providers).any?
          else
            false
          end
        end
      end
    end
  end
end
