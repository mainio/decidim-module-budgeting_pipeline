# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    class HelpContainer
      attr_reader :key

      def initialize(key:)
        @key = key
      end

      def name
        I18n.t("decidim.budgeting_pipeline.help_containers.#{key}.name")
      end

      def self.find(key)
        all.find { |cnt| cnt.key == key.to_sym }
      end

      def self.all
        @all ||= [:index, :pipeline].map do |key|
          new(key:)
        end
      end
    end
  end
end
