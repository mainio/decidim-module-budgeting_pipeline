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
      #
      # Returns a String.
      def title(html_escape: false, all_locales: false)
        return unless project

        super(project.title, html_escape, all_locales)
      end
    end
  end
end
