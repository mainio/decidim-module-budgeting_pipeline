# frozen_string_literal: true

module Decidim
  module Budgets
    # Controls the voting pipeline.
    class VotesController < ApplicationController
      include Decidim::FormFactory
      include Decidim::FilterResource
      include Decidim::Paginable
      include Decidim::Budgets::Orderable
      include Decidim::BudgetingPipeline::OrdersController

      helper_method :help_sections, :voting_steps, :current_step, :sticky_budgets, :suggested_budgets, :choose_budgets, :selected_budgets, :projects

      before_action :ensure_authorized!
      before_action :ensure_not_voted!
      before_action :ensure_orders!, only: [:projects, :choose, :preview, :create]
      before_action :ensure_orders_valid!, only: [:preview, :create]
      before_action :set_current_step

      skip_before_action :ensure_authorized!, only: [:show]
      skip_before_action :ensure_not_voted!, only: [:show]

      def show
        @current_step = :authorization
        return unless user_authorized?
        return ensure_not_voted! if user_voted?

        redirect_to budgets_vote_path
      end

      def budgets
        @form = form(BudgetSelectForm).from_model(current_workflow)
      end

      def start
        @current_step = :budgets

        @form = form(BudgetSelectForm).from_params(params)
        StartVoting.call(@form, current_user, current_workflow) do
          on(:ok) do
            redirect_to projects_vote_path
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("decidim.budgets.votes.start.invalid")
            render "budgets"
          end
        end
      end

      def projects
        @projects = search.results.page(params[:page]).per(current_component.settings.projects_per_page)
        @projects = reorder(@projects)
      end

      def create
        CheckoutOrders.call(current_orders, current_user) do
          on(:ok) do
            flash[:notice] = I18n.t("decidim.budgets.votes.create.success")
            session["decidim-budgets.voted"] = true
            redirect_to results_path
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("decidim.budgets.votes.create.error")
            redirect_to choose_vote_path
          end
        end
      end

      private

      attr_accessor :current_step

      def layout
        "decidim/budgets/participatory_space_plain"
      end

      def ensure_authorized!
        return if user_authorized?

        flash[:warning] = I18n.t("decidim.budgets.votes.general.not_authorized")
        redirect_to vote_path
      end

      def ensure_not_voted!
        return unless user_voted?

        flash[:warning] = I18n.t("decidim.budgets.votes.general.already_voted")
        redirect_to projects_path
      end

      def ensure_orders!
        redirect_to budgets_vote_path unless current_orders.any?
      end

      def ensure_orders_valid!
        return if current_orders.all?(&:confirmed_valid?)

        redirect_to choose_vote_path
      end

      # This ensures that only people eligible to vote can enter the voting
      # pipeline after the authorization step. The authorization conditions
      # should be used to control user's ability to vote (e.g. where they live,
      # how old they are, etc.).
      def user_authorized?
        @user_authorized ||= user_signed_in? && action_authorized_to("vote").ok?
      end

      def user_voted?
        current_workflow.voted.any?
      end

      def set_current_step
        @current_step = action_name.to_sym
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
          sticky_ids = sticky_budgets.map(&:id)
          current_workflow.allowed.reject do |budget|
            sticky_ids.include?(budget.id)
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

            OpenStruct.new(key: key, done: done)
          end

          steps
        end
      end

      def voting_steps_keys
        @voting_steps_keys ||= [
          user_authorized? ? :budgets : :authorization,
          :projects,
          :choose,
          :preview
        ]
      end

      # For the projects page
      def search_klass
        ProjectSearch
      end

      def default_filter_params
        {
          search_text: "",
          status: "all",
          category_id: "all",
          budget_id: "all",
          budget_amount_min: 0,
          budget_amount_max: maximum_project_budget,
          activity: "all"
        }
      end

      def maximum_project_budget
        @maximum_project_budget ||= Decidim::Budgets::Project.where(budget: selected_budgets).maximum(:budget_amount)
      end
    end
  end
end
