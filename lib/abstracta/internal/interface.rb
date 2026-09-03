# frozen_string_literal: true

module Abstracta
  module Internal
    module InterfaceDefinition
      def interface?
        true
      end

      def interface_methods
        Abstracta.interface_instance_methods_for(self)
      end

      def interface_class_methods
        Abstracta.interface_class_methods_for(self)
      end
    end

    class Interface < Module
      attr_reader :instance_methods, :class_methods

      def initialize(instance_methods:, class_methods:)
        super()
        @instance_methods = instance_methods.freeze
        @class_methods = class_methods.freeze
      end

      def included(base)
        unless base.is_a?(Module) && !base.is_a?(Class)
          raise TypeError, "Abstracta.interface must be included in a module"
        end

        Abstracta.define_interface(
          base,
          instance_methods: instance_methods,
          class_methods: class_methods
        )
      end
    end
  end
end
