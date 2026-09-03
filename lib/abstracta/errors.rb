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

      def initialize(abstract_class)
        @abstract_class = abstract_class
        super("#{Abstracta.class_name(abstract_class)} is abstract and cannot be instantiated")
      end
    end

    class UnimplementedMethodsError < AbstractClassInstantiationError
      attr_reader :missing_instance_methods, :missing_class_methods

      def initialize(abstract_class, instance_methods:, class_methods:)
        @abstract_class = abstract_class
        @missing_instance_methods = instance_methods.freeze
        @missing_class_methods = class_methods.freeze

        details = []
        unless instance_methods.empty?
          details << "instance methods: #{instance_methods.map { |name| "##{name}" }.join(", ")}"
        end
        unless class_methods.empty?
          details << "class methods: #{class_methods.map { |name| ".#{name}" }.join(", ")}"
        end

        Error.instance_method(:initialize).bind_call(
          self,
          "#{Abstracta.class_name(abstract_class)} has unimplemented contract #{details.join("; ")}"
        )
      end
    end
  end
end
