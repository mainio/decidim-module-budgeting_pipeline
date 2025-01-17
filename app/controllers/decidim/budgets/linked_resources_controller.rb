# frozen_string_literal: true

module Decidim
  module Budgets
    # Controls linked resources display for projects.
    class LinkedResourcesController < ApplicationController
      include Decidim::ResourceHelper

      before_action :set_project
      before_action :set_resource

      helper_method :resource, :manifest

      def show
        raise ActionController::RoutingError, "Not Found" unless project
        raise ActionController::RoutingError, "Not Found" unless resource
        raise ActionController::RoutingError, "Not Found" unless resource_visible?
        raise ActionController::RoutingError, "Not Found" unless manifest

        # render(partial: resource_manifest.template, locals: { resources: resources })

        # "decidim/plans/plans/linked_plans"
        tpl = manifest.template.split("/")
        tpl.pop
        @template = "#{tpl.join("/")}/linked_resource_display"

        respond_to do |format|
          format.html { redirect_to link_to_resource }
          format.js
        end
      end

      private

      attr_reader :project, :resource

      def set_project
        @project = Decidim::Budgets::Project.find_by(id: params[:project_id])
      end

      def set_resource
        @resource = GlobalID::Locator.locate(params[:id])
      end

      def link_to_resource
        if resource.is_a?(Decidim::Budgets::Project)
          resource_locator([resource.budget, resource]).path
        else
          resource_locator(resource).path
        end
      end

      def manifest
        @manifest ||= resource.try(:resource_manifest)
      end

      def resource_visible?
        return false if resource.respond_to?(:deleted?) && resource.deleted?
        return false if resource.respond_to?(:withdrawn?) && resource.withdrawn?
        return false if resource.respond_to?(:hidden?) && resource.hidden?
        return false if resource.respond_to?(:published?) && !resource.published?

        true
      end
    end
  end
end
