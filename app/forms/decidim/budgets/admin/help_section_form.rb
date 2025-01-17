# frozen_string_literal: true

module Decidim
  module Budgets
    module Admin
      # This class holds a Form to create/update budgeting help sections.
      class HelpSectionForm < Decidim::Form
        include TranslatableAttributes
        include TranslationsHelper
        include Decidim::ApplicationHelper

        translatable_attribute :title, String
        translatable_attribute :description, String
        translatable_attribute :link_text, String

        attribute :weight, Integer
        attribute :link, String
        attribute :image, Decidim::Attributes::Blob
        attribute :remove_image, Decidim::AttributeObject::Model::Boolean, default: false

        validates :title, translatable_presence: true
        validates :description, translatable_presence: true

        validates :image, passthru: {
          to: Decidim::Budgets::HelpSection,
          with: {
            # When the image validations are done through the validation
            # endpoint, the component is unknown and would cause the
            # validations to fail because the component would not exist.
            component: lambda do |form|
              Decidim::Component.new(
                participatory_space: Decidim::ParticipatoryProcess.new(
                  organization: form.current_organization
                )
              )
            end
          }
        }
      end
    end
  end
end
