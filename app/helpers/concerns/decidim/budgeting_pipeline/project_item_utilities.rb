# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    module ProjectItemUtilities
      extend ActiveSupport::Concern

      included do
        # Override the voted_for method for the orders and line items
        # controllers because otherwise the project would be searched against
        # the "current" order. With this module, we may have multiple
        # `current_orders` which is why searching from the `current_order` does
        # not always work.
        #
        # This method is also used in other parts of the application, the above
        # override is just an example.
        def voted_for?(project)
          order = Decidim::Budgets::Order.find_by(user: current_user, budget: project.budget)
          return false unless order

          order.projects.include?(project)
        end
      end

      # Generates a project summary either based on the translated summary field
      # or when that is empty, by stripping the relevant parts from the project
      # description and truncating that to the defined length.
      #
      # The result is a plain text string without any HTML markup.
      #
      # Returns a String.
      def project_summary_for(project)
        text = translated_attribute(project.summary)
        return decidim_sanitize(text) if text.present?

        # Strip the headings off the description text
        text = translated_attribute(project.description)
        doc = Nokogiri::HTML(text)
        doc.css("h1, h2, h3, h4, h5, h6").remove

        truncate(strip_tags(doc.at("body").inner_html), length: 100)
      end
    end
  end
end
