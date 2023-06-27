# frozen_string_literal: true

module Decidim
  module Budgets
    module Admin
      # This command is executed when the user updates a budgeting help section.
      class UpdateHelpSection < Rectify::Command
        include Decidim::AttachmentAttributesMethods

        def initialize(form, section)
          @form = form
          @section = section
        end

        # Updates the budget if valid.
        #
        # Broadcasts :ok if successful, :invalid otherwise.
        def call
          return broadcast(:invalid) if form.invalid?

          update_section!

          broadcast(:ok, section)
        end

        private

        attr_reader :form, :section

        def update_section!
          attributes = {
            weight: form.weight,
            title: form.title,
            description: form.description,
            link: form.link,
            link_text: form.link_text
          }.merge(attachment_attributes(:image))

          Decidim.traceability.update!(
            section,
            form.current_user,
            attributes,
            visibility: "all"
          )
        end
      end
    end
  end
end
