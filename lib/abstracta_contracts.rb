# frozen_string_literal: true

require_relative "abstracta_contracts/version"
require_relative "abstracta_contracts/errors"
require_relative "abstracta_contracts/internal/class_methods"
require_relative "abstracta_contracts/internal/constructor_guard"
require_relative "abstracta_contracts/internal/contract"
require_relative "abstracta_contracts/internal/interface"

module AbstractaContracts
  MUTEX_CREATION_LOCK = Mutex.new
  private_constant :MUTEX_CREATION_LOCK

  class << self
    def included(base)
      install(base)
    end

    def with_methods(*methods, class_methods: [])
      instance_methods = normalize_method_names(methods)
      singleton_methods = normalize_method_names(Array(class_methods))

      if instance_methods.empty? && singleton_methods.empty?
        raise ArgumentError, "at least one abstract instance or class method is required"
      end

      Internal::Contract.new(instance_methods: instance_methods, class_methods: singleton_methods)
    end

    def interface(*methods, class_methods: [])
      instance_methods = normalize_method_names(methods)
      singleton_methods = normalize_method_names(Array(class_methods))

      if instance_methods.empty? && singleton_methods.empty?
        raise ArgumentError, "at least one interface instance or class method is required"
      end

      Internal::Interface.new(instance_methods: instance_methods, class_methods: singleton_methods)
    end

    def install(base)
      raise TypeError, "AbstractaContracts can only be included in classes" unless base.is_a?(Class)

      base.extend(Internal::ClassMethods) unless base.singleton_class < Internal::ClassMethods
      base.singleton_class.prepend(Internal::ConstructorGuard) unless base.singleton_class < Internal::ConstructorGuard
      mutex_for(base)
      base
    end

    def define_interface(base, instance_methods:, class_methods:)
      if base.instance_variable_defined?(:@abstracta_contracts_interface_defined)
        raise Internal::InterfaceAlreadyDefinedError,
              "#{interface_name(base)} is already an AbstractaContracts interface"
      end

      base.instance_variable_set(:@abstracta_contracts_interface_defined, true)
      base.instance_variable_set(:@abstracta_contracts_interface_instance_methods, instance_methods.freeze)
      base.instance_variable_set(:@abstracta_contracts_interface_class_methods, class_methods.freeze)
      base.extend(Internal::InterfaceDefinition) unless base.singleton_class < Internal::InterfaceDefinition
      base
    end

    def interface?(object)
      object.is_a?(Module) && object.respond_to?(:interface?) && object.interface?
    end

    def validate_interface!(interface)
      return interface if interface?(interface)

      raise Internal::InvalidInterfaceError, "#{interface.inspect} is not an AbstractaContracts interface"
    end

    def normalize_interfaces(interfaces)
      interfaces.flatten.map { |interface| validate_interface!(interface) }.uniq.freeze
    end

    def normalize_method_names(names)
      names.flatten.map do |name|
        unless name.is_a?(String) || name.is_a?(Symbol)
          raise Internal::InvalidMethodNameError, "abstract method names must be Strings or Symbols, got #{name.class}"
        end

        normalized = name.to_s
        if normalized.empty? || normalized.match?(/\s/)
          raise Internal::InvalidMethodNameError, "invalid abstract method name: #{name.inspect}"
        end

        normalized.to_sym
      end.uniq.freeze
    end

    def register_instance_methods(base, names)
      install(base)
      synchronize(base) do
        declared = base.send(:abstracta_contracts_declared_instance_methods)
        names.each { |name| declared << name unless declared.include?(name) }
      end
    end

    def register_class_methods(base, names)
      install(base)
      synchronize(base) do
        declared = base.send(:abstracta_contracts_declared_class_methods)
        names.each { |name| declared << name unless declared.include?(name) }
      end
    end

    def required_instance_methods_for(klass)
      required_methods_for(klass, :abstracta_contracts_declared_instance_methods)
    end

    def required_class_methods_for(klass)
      required_methods_for(klass, :abstracta_contracts_declared_class_methods)
    end

    def missing_instance_methods_for(klass)
      required_instance_methods_for(klass).filter_map do |name, declaration_owner|
        name unless implemented_after_declaration?(klass, name, declaration_owner, singleton: false)
      end
    end

    def missing_class_methods_for(klass)
      required_class_methods_for(klass).filter_map do |name, declaration_owner|
        name unless implemented_after_declaration?(klass, name, declaration_owner, singleton: true)
      end
    end

    def interfaces_for(klass)
      result = []

      klass.ancestors.reverse_each do |ancestor|
        next unless ancestor.is_a?(Class)
        next unless ancestor.respond_to?(:abstracta_contracts_direct_interfaces, true)

        ancestor.send(:abstracta_contracts_direct_interfaces).each do |interface|
          interface_hierarchy(interface).each { |candidate| result << candidate unless result.include?(candidate) }
        end
      end

      result
    end

    def interface_instance_methods_for(interface)
      validate_interface!(interface)
      interface_hierarchy(interface).flat_map do |candidate|
        candidate.instance_variable_get(:@abstracta_contracts_interface_instance_methods) || []
      end.uniq.freeze
    end

    def interface_class_methods_for(interface)
      validate_interface!(interface)
      interface_hierarchy(interface).flat_map do |candidate|
        candidate.instance_variable_get(:@abstracta_contracts_interface_class_methods) || []
      end.uniq.freeze
    end

    def required_interface_instance_methods_for(klass)
      interfaces_for(klass).flat_map { |interface| interface_instance_methods_for(interface) }.uniq
    end

    def required_interface_class_methods_for(klass)
      interfaces_for(klass).flat_map { |interface| interface_class_methods_for(interface) }.uniq
    end

    def missing_interface_instance_methods_for(klass)
      required_interface_instance_methods_for(klass).reject do |name|
        method_available?(klass, name, singleton: false)
      end
    end

    def missing_interface_class_methods_for(klass)
      required_interface_class_methods_for(klass).reject do |name|
        method_available?(klass, name, singleton: true)
      end
    end

    def synchronize(base, &)
      mutex_for(base).synchronize(&)
    end

    def class_name(klass)
      klass.name || klass.inspect
    end

    def interface_name(interface)
      interface.name || interface.inspect
    end

    private

    def mutex_for(base)
      if base.instance_variable_defined?(:@abstracta_contracts_mutex)
        return base.instance_variable_get(:@abstracta_contracts_mutex)
      end

      MUTEX_CREATION_LOCK.synchronize do
        base.instance_variable_get(:@abstracta_contracts_mutex) ||
          base.instance_variable_set(:@abstracta_contracts_mutex, Mutex.new)
      end
    end

    def required_methods_for(klass, reader)
      declarations = {}

      klass.ancestors.reverse_each do |ancestor|
        next unless ancestor.is_a?(Class)
        next unless ancestor.respond_to?(reader, true)

        ancestor.send(reader).each { |name| declarations[name] = ancestor }
      end

      declarations.freeze
    end

    def implemented_after_declaration?(klass, name, declaration_owner, singleton:)
      lookup_class = singleton ? klass.singleton_class : klass
      declaration_lookup_owner = singleton ? declaration_owner.singleton_class : declaration_owner

      implementation_owner = lookup_class.instance_method(name).owner
      return true if implementation_owner == declaration_lookup_owner

      ancestors = lookup_class.ancestors
      implementation_index = ancestors.index(implementation_owner)
      declaration_index = ancestors.index(declaration_lookup_owner)

      implementation_index && declaration_index && implementation_index < declaration_index
    rescue NameError
      false
    end

    def method_available?(klass, name, singleton:)
      lookup = singleton ? klass.singleton_class : klass
      lookup.instance_method(name)
      true
    rescue NameError
      false
    end

    def interface_hierarchy(interface)
      validate_interface!(interface)

      interface.ancestors.reverse_each.with_object([]) do |ancestor, result|
        next unless interface?(ancestor)

        result << ancestor unless result.include?(ancestor)
      end
    end
  end
end
