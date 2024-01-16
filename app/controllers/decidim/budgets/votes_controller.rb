# frozen_string_literal: true

module Decidim
  module Budgets
    # Controls the voting pipeline.
    class VotesController < ApplicationController
      include Decidim::FormFactory
      include Decidim::FilterResource
      include Decidim::Paginable
      include Decidim::TranslatableAttributes
      include Decidim::Budgets::Orderable
      include Decidim::BudgetingPipeline::Authorizable
      include Decidim::BudgetingPipeline::Orderable
      include Decidim::BudgetingPipeline::OrdersUtilities
      include Decidim::BudgetingPipeline::VoteUtilities

      helper Decidim::BudgetingPipeline::AuthorizationHelper

      helper_method(
        :user_authorized?,
        :help_sections,
        :voting_steps,
        :current_step,
        :prev_step,
        :next_step,
        :sticky_budgets,
        :highlighted_budgets,
        :suggested_budgets,
        :choose_budgets,
        :selected_budgets,
        :projects
      )

      before_action :ensure_voting_open!
      before_action :ensure_authorized!
      before_action :ensure_not_voted!, except: [:finished]
      before_action :ensure_orders!, only: [:projects, :preview, :create]
      before_action :ensure_orders_valid!, only: [:preview, :create]
      before_action :set_current_step

      skip_before_action :ensure_authorized!, only: [:show]
      skip_before_action :ensure_not_voted!, only: [:show]

      def show
        return redirect_to(routes_proxy.projects_path) unless user_signed_in?

        define_step(authorization_required? ? :authorization : :login)
        return unless user_authorized?
        return ensure_not_voted! if user_voted?
        return if current_workflow.progress.blank? && translated_attribute(component_settings.vote_privacy_content).present?

        redirect_to routes_proxy.budgets_vote_path
      end

      def budgets
        @form = form(BudgetSelectForm).from_model(current_workflow)
      end

      def start
        define_step(:budgets)

        @form = form(BudgetSelectForm).from_params(params)
        StartVoting.call(@form, current_user, current_workflow) do
          on(:ok) do
            redirect_to routes_proxy.projects_vote_path
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("decidim.budgets.votes.start.invalid")
            render "budgets"
          end
        end
      end

      def projects
        @projects = reorder(search.result)
      end

      def create
        CheckoutOrders.call(current_orders, current_user) do
          on(:ok) do
            # Do not display a flash message with a successful vote because it
            # would force the focus within the flash message instead of the
            # popup which is displayed after a successful vote. This is
            # important for screen reader users who need to hear the modal
            # content when it is displayed.
            # session["decidim-budgets.voted"] = true
            if current_settings.show_votes?
              redirect_to routes_proxy.results_path
            else
              redirect_to routes_proxy.finished_vote_path
            end
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("decidim.budgets.votes.create.error")
            redirect_to projects_vote_path
          end
        end
      end

      def finished
        redirect_to(routes_proxy.projects_path) if !user_signed_in? || !user_voted?
      end

      private

      attr_accessor :current_step, :prev_step, :next_step

      def layout
        "decidim/budgets/participatory_space_plain"
      end

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

      def ensure_authorized!
        return if user_authorized?

        flash[:warning] = I18n.t("decidim.budgets.votes.general.not_authorized")
        redirect_to routes_proxy.vote_path
      end

      def ensure_not_voted!
        return unless user_voted?

        flash[:warning] = I18n.t("decidim.budgets.votes.general.already_voted")
        redirect_to routes_proxy.projects_path
      end

      def ensure_orders!
        redirect_to routes_proxy.budgets_vote_path unless current_orders.any?
      end

      def ensure_orders_valid!
        return if can_cast_votes?

        redirect_to routes_proxy.projects_vote_path
      end

      def set_current_step
        define_step(action_name.to_sym)
      end

      def define_step(step_name)
        @current_step = step_name

        @voting_steps = nil # Force reset of the voting steps if already set
        @prev_step = nil
        @next_step = nil
        voting_steps.each_with_index do |step, i|
          next unless step.key == @current_step

          @prev_step = voting_steps[i - 1]&.key
          @next_step = voting_steps[i + 1]&.key
        end
      end

      def help_sections
        @help_sections ||= Decidim::Budgets::HelpSection.where(
          component: current_component,
          key: "pipeline"
        ).order(:weight)
      end

      # The budgets to choose from. These are all budgets except the sticky
      # one(s) that will be automatically selected.
      def choose_budgets
        @choose_budgets ||= begin
          suggested_ids = suggested_budgets.map(&:id)
          current_workflow.budgets.reject do |budget|
            suggested_ids.include?(budget.id)
          end
        end
      end

      def sticky_budgets
        @sticky_budgets ||=
          if current_workflow.respond_to?(:sticky)
            current_workflow.sticky
          else
            []
          end
      end

      def highlighted_budgets
        @highlighted_budgets ||= current_workflow.highlighted
      end

      def suggested_budgets
        @suggested_budgets ||=
          if current_workflow.respond_to?(:suggested)
            current_workflow.suggested
          else
            []
          end
      end

      def selected_budgets
        @selected_budgets ||= Decidim::Budgets::Budget.where(
          id: current_orders.map(&:decidim_budgets_budget_id)
        ).order(weight: :asc)
      end

      def voting_steps
        @voting_steps ||= begin
          done = true
          steps = voting_steps_keys.map do |key|
            done = false if key == current_step
            step_link = [:authorization, :login].include?(key) ? routes_proxy.vote_path : routes_proxy.public_send("#{key}_vote_path")
            available =
              case key
              when :authorization, :login
                true
              when :budgets
                user_authorized?
              when :projects
                current_orders.any?
              when :preview
                can_cast_votes?
              else
                false
              end

            OpenStruct.new(key: key, done: done, available: available, link: step_link)
          end

          steps
        end
      end

      def voting_steps_keys
        @voting_steps_keys ||= begin
          first_step_key =
            if user_authorized?
              :budgets
            elsif authorization_required?
              :authorization
            else
              :login
            end

          [
            first_step_key,
            :projects,
            :preview
          ]
        end
      end

      # For the projects page
      def search_collection
        Decidim::Budgets::Project.joins(:budget).where(
          budget: selected_budgets
        ).includes([:scope, :component, :attachments, :category])
      end

      def default_filter_params
        {
          search_text_cont: "",
          with_any_status: %w(all),
          with_any_scope: default_filter_scope_params,
          with_any_category: "all",
          decidim_budgets_budget_id_eq: nil,
          budget_amount_gteq: 0,
          budget_amount_lteq: maximum_project_budget,
          favorites: nil,
          selected: nil
        }
      end

      def maximum_project_budget
        @maximum_project_budget ||= Decidim::Budgets::Project.where(budget: selected_budgets).maximum(:budget_amount)
      end

      def routes_proxy
        @routes_proxy ||= EngineRouter.main_proxy(current_component)
      end
    end
  end
end
