# frozen_string_literal: true

module Decidim
  module Budgets
    module Admin
      # A command with all the business logic when an admin exports projects to
      # a single accountability component.
      class ExportProjectsToAccountability < Decidim::Command
        include ActionView::Helpers::TextHelper

        # Public: Initializes the command.
        #
        # form - A form object with the params.
        def initialize(form)
          @form = form
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) unless @form.valid?

          broadcast(:ok, create_results_from_selected_projects)
        end

        private

        attr_reader :form

        def create_results_from_selected_projects
          transaction do
            projects.map do |original_project|
              next if project_already_linked?(original_project, target_component)

              result = Decidim.traceability.create!(
                Decidim::Accountability::Result,
                form.current_user,
                result_attributes_from(original_project),
                visibility: "all"
              )

              # Create the attachments
              original_project.attachments.each do |at|
                Decidim::Attachment.create!(
                  attached_to: result,
                  title: at.title,
                  file: at.file
                )
              end

              # Link included proposals to the result
              proposals = original_project.linked_resources(:proposals, "included_proposals")
              result.link_resources(proposals, "included_proposals")

              # Link included ideas to the result
              ideas = original_project.linked_resources(:ideas, "included_ideas")
              result.link_resources(ideas, "included_ideas")

              # Link included plans to the result
              plans = original_project.linked_resources(:plans, "included_plans")
              result.link_resources(plans, "included_plans")

              # Link the project to the result
              result.link_resources([original_project], "included_projects")

              # Map the location if necessary
              map_result_location(result, original_project)

              result
            end.compact
          end
        end

        def result_attributes_from(original_project, weight: 0)
          {
            component: target_component,
            scope: original_project.scope || original_project.budget.scope,
            category: original_project.category,
            title: sanitize_localized(original_project.title),
            description: original_project.description,
            progress: statuses.first&.progress || 0,
            status: statuses.first,
            weight: weight
          }.merge(extra_result_attributes_from(original_project))
        end

        def sanitize_localized(hash)
          hash.each do |locale, value|
            next if value.is_a?(Hash)

            hash[locale] = sanitize(value, tags: [])
          end
        end

        def extra_result_attributes_from(original_project)
          extra = {}

          # Summary field is only available if the accountability simple is
          # installed but may be also manually defined.
          extra[:summary] = original_project.summary if Decidim::Accountability::Result.column_names.include?("summary")

          # Map the accountability simple fields if available
          if defined?(Decidim::AccountabilitySimple)
            image = original_project&.main_image
            image ||= original_project.photos.first&.file
            if image
              extra[:main_image] = image
              extra[:list_image] = image
            end
          end

          # Extra fields that may be available
          extra[:budget_amount] = original_project.budget_amount if Decidim::Accountability::Result.column_names.include?("budget_amount")

          extra
        end

        def budgets
          @budgets ||= Decidim::Budgets::Budget.where(component: origin_component).order(:weight)
        end

        def projects
          @projects ||= Decidim::Budgets::Project.where(budget: budgets).where.not(selected_at: nil).order(:id)
        end

        def statuses
          @statuses ||= Decidim::Accountability::Status.where(component: target_component).order(:progress)
        end

        def origin_component
          @form.current_component
        end

        def target_component
          @form.target_component
        end

        def project_already_linked?(original_project, target_component)
          # Search through the resource links manually because the
          # `linked_resources` method won't return any resources if the target
          # component is not published yet.
          original_project.resource_links_to.where(
            name: "included_projects",
            from_type: "Decidim::Accountability::Result"
          ).any? do |link|
            link.from && link.from.component == target_component
          end
        end

        def map_result_location(result, original_project)
          return unless original_project.respond_to?(:address)
          return if original_project.address.blank?
          return unless result.respond_to?(:locations)

          result.locations.create!(
            address: original_project.address,
            latitude: original_project.latitude,
            longitude: original_project.longitude
          )
        end
      end
    end
  end
end
