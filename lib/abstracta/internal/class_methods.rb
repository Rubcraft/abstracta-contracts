# frozen_string_literal: true

module Abstracta
  module Internal
    module ClassMethods
      def abstract_class!
        Abstracta.synchronize(self) { @abstracta_explicitly_abstract = true }
        self
      end

      def abstract_method(*names)
        Abstracta.register_instance_methods(self, Abstracta.normalize_method_names(names))
        self
      end

      def abstract_class_method(*names)
        Abstracta.register_class_methods(self, Abstracta.normalize_method_names(names))
        self
      end

      def implements(*interfaces)
        normalized = Abstracta.normalize_interfaces(interfaces)

        Abstracta.synchronize(self) do
          direct = abstracta_direct_interfaces
          normalized.each { |interface| direct << interface unless direct.include?(interface) }
        end

        normalized.each { |interface| include(interface) unless self < interface }
        self
      end

      def explicitly_abstract?
        @abstracta_explicitly_abstract == true
      end

      def abstract?
        explicitly_abstract? || !missing_methods.empty? || !missing_class_methods.empty?
      end

      def concrete?
        !abstract?
      end

      def abstract_methods
        Abstracta.required_instance_methods_for(self).keys.freeze
      end

      def abstract_class_methods
        Abstracta.required_class_methods_for(self).keys.freeze
      end

      def missing_abstract_methods
        Abstracta.missing_instance_methods_for(self).freeze
      end

      def missing_abstract_class_methods
        Abstracta.missing_class_methods_for(self).freeze
      end

      def direct_interfaces
        abstracta_direct_interfaces.dup.freeze
      end

      def interfaces
        Abstracta.interfaces_for(self).freeze
      end

      def implements?(interface)
        Abstracta.validate_interface!(interface)
        interfaces.include?(interface)
      end

      def interface_methods
        Abstracta.required_interface_instance_methods_for(self).freeze
      end

      def interface_class_methods
        Abstracta.required_interface_class_methods_for(self).freeze
      end

      def missing_interface_methods
        Abstracta.missing_interface_instance_methods_for(self).freeze
      end

      def missing_interface_class_methods
        Abstracta.missing_interface_class_methods_for(self).freeze
      end

      def missing_methods
        (missing_abstract_methods + missing_interface_methods).uniq.freeze
      end

      def missing_class_methods
        (missing_abstract_class_methods + missing_interface_class_methods).uniq.freeze
      end

      def valid_implementation?
        concrete?
      end

      def validate_implementation!
        return true if concrete?

        missing = { instance_methods: missing_methods, class_methods: missing_class_methods }
        raise Internal::UnimplementedMethodsError.new(self, **missing) unless missing.values.all?(&:empty?)

        raise Internal::AbstractClassInstantiationError, self
      end

      private

      def abstracta_declared_instance_methods
        @abstracta_declared_instance_methods ||= []
      end

      def abstracta_declared_class_methods
        @abstracta_declared_class_methods ||= []
      end

      def abstracta_direct_interfaces
        @abstracta_direct_interfaces ||= []
      end
    end
  end
end
