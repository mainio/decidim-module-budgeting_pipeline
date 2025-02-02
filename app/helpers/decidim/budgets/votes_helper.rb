# frozen_string_literal: true

module Decidim
  module Budgets
    module VotesHelper
      def voting_step_link(step)
        mobile_tag = content_tag :span, class: "step-selector hide-for-mediumlarge" do
          yield
        end
        desktop_tag = begin
          attributes = { class: "step-selector show-for-mediumlarge" }
          attributes[:aria] = { current: "step" } if step.key == current_step

          link_to step.link, attributes do
            yield
          end
        end

        mobile_tag + desktop_tag
      end

      def order_values
        available_orders.index_with do |value|
          t(value, scope: "decidim.budgets.projects.orders")
        end
      end

      def display_more_information?
        translated_attribute(component_settings.more_information_modal).present?
      end

      def more_information_label
        label = translated_attribute(component_settings.more_information_modal_label)
        return label if label.present?

        t("decidim.budgets.votes.budgets.show_more_information_default")
      end

      def project_selected?(project)
        order = current_orders.find { |ord| ord.decidim_budgets_budget_id == project.decidim_budgets_budget_id }
        return false unless order

        order.projects.any? { |pr| pr.id == project.id }
      end
    end
  end
end
