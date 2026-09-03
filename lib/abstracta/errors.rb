# frozen_string_literal: true

module Abstracta
  # Public base exception for all Abstracta errors.
  class Error < StandardError; end

  module Internal
    class InvalidMethodNameError < Error; end
    class InvalidInterfaceError < Error; end
    class InterfaceAlreadyDefinedError < Error; end

    class AbstractClassInstantiationError < Error
      attr_reader :abstract_class

      def initialize(abstract_class, message: nil)
        @abstract_class = abstract_class
        super(message || "#{Abstracta.class_name(abstract_class)} is abstract and cannot be instantiated")
      end
    end

    class UnimplementedMethodsError < AbstractClassInstantiationError
      attr_reader :missing_instance_methods, :missing_class_methods

      def initialize(abstract_class, instance_methods:, class_methods:)
        @missing_instance_methods = instance_methods.freeze
        @missing_class_methods = class_methods.freeze
        super(abstract_class, message: unimplemented_message(abstract_class, instance_methods, class_methods))
      end

      private

      def unimplemented_message(abstract_class, instance_methods, class_methods)
        details = []
        unless instance_methods.empty?
          details << "instance methods: #{instance_methods.map { |name| "##{name}" }.join(', ')}"
        end
        details << "class methods: #{class_methods.map { |name| ".#{name}" }.join(', ')}" unless class_methods.empty?

        "#{Abstracta.class_name(abstract_class)} has unimplemented contract #{details.join('; ')}"
      end
    end
  end
end
