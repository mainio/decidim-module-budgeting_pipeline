# frozen_string_literal: true

module Decidim
  module Budgets
    # A cell to display when a vote has been created.
    class VoteActivityCell < ActivityCell
      # The link to the resource linked to the activity.
      def resource_link_path
        routes.orders_path
      end

      # The text to show as the link to the resource.
      def resource_link_text
        decidim_html_escape(
          t(
            "decidim.budgets.last_activity.show_vote_at",
            name: translated_attribute(resource.participatory_space.title)
          )
        )
      end

      # The title at the header of the item.
      def title
        I18n.t(
          "decidim.budgets.last_activity.voted_at_html",
          link: participatory_space_link
        )
      end

      # Link to the participatory space where the activity happened.
      def participatory_space_link
        link_to(
          decidim_html_escape(translated_attribute(participatory_space.title)),
          routes.root_path
        )
      end

      private

      def routes
        @routes ||= EngineRouter.main_proxy(resource.component)
      end
    end
  end
end
