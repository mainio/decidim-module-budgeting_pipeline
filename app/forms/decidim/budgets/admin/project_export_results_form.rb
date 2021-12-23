# frozen_string_literal: true

module Decidim
  module Budgets
    module Admin
      # A form object to be used when admin users want to export a collection of
      # selected projects into the accountability component as results.
      class ProjectExportResultsForm < Decidim::Form
        mimic :accountability_export

        attribute :target_component_id, Integer
        attribute :export_all_selected_projects, Boolean

        validates :target_component_id, :target_component, presence: true
        validates :export_all_selected_projects, allow_nil: false, acceptance: true

        def target_component
          @target_component ||= target_components.find_by(id: target_component_id)
        end

        def target_components
          @target_components ||= components_for(current_participatory_space)
        end

        def components_for(participatory_space)
          participatory_space.components.where(manifest_name: :accountability)
        end

        def target_components_collection
          target_components.map do |component|
            [component.name[I18n.locale.to_s], component.id]
          end
        end
      end
    end
  end
end
