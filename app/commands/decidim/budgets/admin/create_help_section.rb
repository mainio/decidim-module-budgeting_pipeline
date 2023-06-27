# frozen_string_literal: true

module Decidim
  module Budgets
    module Admin
      # This command is executed when the user creates a budgeting help section.
      class CreateHelpSection < Rectify::Command
        include Decidim::AttachmentAttributesMethods

        def initialize(form, container)
          @form = form
          @container = container
        end

        # Creates the budget if valid.
        #
        # Broadcasts :ok if successful, :invalid otherwise.
        def call
          return broadcast(:invalid) if form.invalid?

          create_section!

          broadcast(:ok, section)
        end

        private

        attr_reader :form, :container, :section

        def create_section!
          attributes = {
            component: form.current_component,
            key: container.key,
            weight: form.weight,
            title: form.title,
            description: form.description,
            link: form.link,
            link_text: form.link_text
          }.merge(attachment_attributes(:image))

          @section = Decidim.traceability.create!(
            Decidim::Budgets::HelpSection,
            form.current_user,
            attributes,
            visibility: "all"
          )
        end
      end
    end
  end
end
