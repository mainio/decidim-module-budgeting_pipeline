# frozen_string_literal: true

module Decidim
  module Budgets
    #
    # Decorator for projects
    #
    # Needed to be able to display the resource links for projects.
    #
    class ProjectPresenter < Decidim::ResourcePresenter
      def project
        __getobj__
      end

      # Render the project title
      #
      # links - should render hashtags as links?
      # extras - should include extra hashtags?
      #
      # Returns a String.
      def title(links: false, extras: true, html_escape: false, all_locales: false)
        return unless project

        super project.title, links, html_escape, all_locales, extras:
      end
    end
  end
end
