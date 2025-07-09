# frozen_string_literal: true

module Decidim
  module Budgets
    # Controls cancelling votes
    class CancelController < ApplicationController
      include Decidim::BudgetingPipeline::VoteUtilities
      include Decidim::BudgetingPipeline::OrdersUtilities

      before_action :ensure_voting_open!
      before_action :ensure_checked_out_orders!

      def destroy
        CancelVote.call(current_vote, current_user) do
          on(:ok) do
            flash[:notice] = I18n.t("orders.destroy.success", scope: "decidim")
            redirect_to routes_proxy.projects_path
          end

          on(:invalid) do
            flash[:alert] = I18n.t("orders.destroy.error", scope: "decidim")
            redirect_to routes_proxy.cancel_orders_path
          end
        end
      end

      private

      def ensure_voting_open!
        return if voting_open?

        flash[:warning] =
          if voting_finished?
            I18n.t("decidim.budgets.votes.general.voting_over")
          else
            I18n.t("decidim.budgets.votes.general.voting_blocked")
          end

        if current_settings.show_votes?
          redirect_to routes_proxy.results_path
        else
          redirect_to routes_proxy.projects_path
        end
      end

      def ensure_checked_out_orders!
        return redirect_to decidim.new_user_session_path unless user_signed_in?
        return if current_vote.present? && current_orders.any? && current_orders.all?(&:checked_out?)

        flash[:warning] = I18n.t("decidim.budgets.orders.index.not_voted")
        redirect_to EngineRouter.main_proxy(current_component).projects_path
      end

      def current_vote
        @current_vote = Decidim::Budgets::Vote.find_by(component: current_component, user: current_user)
      end

      def routes_proxy
        @routes_proxy ||= EngineRouter.main_proxy(current_component)
      end
    end
  end
end
