# frozen_string_literal: true

module Decidim
  module BudgetingPipeline
    class SettingsManipulator
      attr_reader :settings

      def initialize(settings)
        @settings = settings
      end

      def move_attribute_after(target_key, after_key)
        move_attribute_relative(target_key, after_key, 1)
      end

      def move_attribute_before(target_key, before_key)
        move_attribute_relative(target_key, before_key, 0)
      end

      def move_attribute_relative(target_key, relative_key, modifier)
        order = settings.attributes.keys
        index = order.index(target_key)
        return unless index

        position = order.index(relative_key)
        return unless position

        order.insert(position + modifier, order.delete_at(index))
        reorder_attributes(order)
      end

      def reorder_attributes(keys)
        settings.instance_variable_set(
          :@attributes,
          settings.attributes.sort_by { |k, _v| keys.index(k) }.to_h
        )
      end
    end
  end
end
