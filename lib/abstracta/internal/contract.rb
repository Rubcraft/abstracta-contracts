# frozen_string_literal: true

module Abstracta
  module Internal
    class Contract < Module
      attr_reader :instance_methods, :class_methods

      def initialize(instance_methods:, class_methods:)
        super()
        @instance_methods = instance_methods.freeze
        @class_methods = class_methods.freeze
      end

      def included(base)
        Abstracta.install(base)
        base.abstract_method(*instance_methods) unless instance_methods.empty?
        base.abstract_class_method(*class_methods) unless class_methods.empty?
      end
    end
  end
end
