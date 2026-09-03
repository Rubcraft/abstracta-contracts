# frozen_string_literal: true

module AbstractaContracts
  module Internal
    module InterfaceDefinition
      def interface?
        true
      end

      def interface_methods
        AbstractaContracts.interface_instance_methods_for(self)
      end

      def interface_class_methods
        AbstractaContracts.interface_class_methods_for(self)
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
          raise TypeError, "AbstractaContracts.interface must be included in a module"
        end

        AbstractaContracts.define_interface(
          base,
          instance_methods: instance_methods,
          class_methods: class_methods
        )
      end
    end
  end
end
