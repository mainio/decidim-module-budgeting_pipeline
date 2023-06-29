# frozen_string_literal: true

module Decidim
  module Budgets
    module Admin
      # This command is executed when the user destroys a HelpSection
      # from the admin panel.
      class DestroyHelpSection < Decidim::Command
        def initialize(section, current_user)
          @section = section
          @current_user = current_user
        end

        # Destroys the help section if valid.
        #
        # Broadcasts :ok if successful, :invalid otherwise.
        def call
          destroy_section!

          broadcast(:ok, section)
        end

        private

        attr_reader :section, :current_user

        def destroy_section!
          Decidim.traceability.perform_action!(
            :delete,
            section,
            current_user,
            visibility: "all"
          ) do
            section.destroy!
          end
        end
      end
    end
  end
end
