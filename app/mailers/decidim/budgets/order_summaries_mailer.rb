# frozen_string_literal: true

module Decidim
  module Budgets
    class OrderSummariesMailer < Decidim::ApplicationMailer
      include Decidim::TranslationsHelper
      include Decidim::SanitizeHelper

      helper Decidim::TranslationsHelper

      # Send an email to an user with the summary of the order.
      #
      # order - the order that was just created
      def order_summaries(orders, user)
        # In case the vote is casted exactly at the same time on multiple
        # machines, the latest order will always have the orders mapped to it.
        # This shouldn't be possible under normal conditions but in case this
        # happens anyways, this prevents the mailer from erroring out.
        return if orders.count < 1

        with_user(user) do
          @user = user
          @orders = orders
          @budget_names = @orders.map { |order| translated_attribute(order.budget.title) }

          @component = @orders.first.budget.component
          @space = @component.participatory_space
          @organization = @space.organization

          subject = I18n.t(
            "order_summaries.subject",
            scope: "decidim.budgets.order_summaries_mailer",
            budget_names: @budget_names.join(", ")
          )
          mail(to: user.email, subject: subject)
        end
      end
    end
  end
end
