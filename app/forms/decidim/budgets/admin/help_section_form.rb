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
          with: { component: ->(form) { form.current_component } }
        }
      end
    end
  end
end
