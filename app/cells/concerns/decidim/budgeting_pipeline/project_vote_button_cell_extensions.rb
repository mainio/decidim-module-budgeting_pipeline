# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    module ProjectVoteButtonCellExtensions
      extend ActiveSupport::Concern

      included do
        def authorization_redirect_path
          EngineRouter.main_proxy(current_component).vote_path
        end
      end
    end
  end
end
