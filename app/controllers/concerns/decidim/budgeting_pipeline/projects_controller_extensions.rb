# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    # Customizes the main projects controller
    module ProjectsControllerExtensions
      extend ActiveSupport::Concern

      include Decidim::Paginable
      include Decidim::BudgetingPipeline::VoteUtilities

      included do
        helper_method :help_sections, :geocoded_projects, :budgets, :maximum_project_budget, :statuses_available?, :vote_success?

        def index; end

        def show
          raise ActionController::RoutingError, "Not Found" unless project
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

        def context_params
          {
            budget: budget,
            component: current_component,
            organization: current_organization,
            current_user: current_user
          }
        end

        # Available orders based on enabled settings
        def available_orders
          @available_orders ||= begin
            available_orders = []
            if votes_are_visible?
              available_orders +=
                if voting_open?
                  %w(random most_voted)
                else
                  %w(most_voted random)
                end
            else
              available_orders << "random"
            end
            available_orders += %w(alphabetical highest_cost lowest_cost)
            available_orders
          end
        end

        def reorder(projects)
          case order
          when "highest_cost"
            projects.order(budget_amount: :desc)
          when "lowest_cost"
            projects.order(budget_amount: :asc)
          when "most_voted"
            if votes_are_visible?
              projects.order_by_most_voted
            else
              projects
            end
          when "alphabetical"
            projects.order("title->>'#{Arel.sql(current_locale)}'")
          when "random"
            projects.order_randomly(random_seed)
          else
            projects
          end
        end
      end

      private

      def help_sections
        @help_sections ||= Decidim::Budgets::HelpSection.where(
          component: current_component,
          key: "index"
        ).order(:weight)
      end

      def geocoded_projects
        @geocoded_projects ||= begin
          base_query = search.results.includes(:category, :component, :scope)
          base_query.geocoded_data_for(current_component)
        end
      end

      def budgets
        @budgets ||= Decidim::Budgets::Budget.where(component: current_component).order(weight: :asc)
      end

      def maximum_project_budget
        @maximum_project_budget ||= Decidim::Budgets::Project.where(budget: budgets).maximum(:budget_amount)
      end

      def statuses_available?
        @statuses_available ||= Decidim::Budgets::Project.where(budget: budgets).where.not(selected_at: nil).any?
      end

      def vote_success?
        @vote_success ||= session.delete("decidim-budgets.voted") == true
      end
    end
  end
end
