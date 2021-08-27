# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    module TextUtilities
      extend ActiveSupport::Concern

      def nonbreaking_text(text)
        text.gsub(" ", "&nbsp;").html_safe
      end
    end
  end
end
