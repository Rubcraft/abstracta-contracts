# frozen_string_literal: true

require_relative "abstracta_contracts/version"
require_relative "abstracta_contracts/errors"
require_relative "abstracta_contracts/internal/class_methods"
require_relative "abstracta_contracts/internal/constructor_guard"
require_relative "abstracta_contracts/internal/contract"
require_relative "abstracta_contracts/internal/interface"

# Declarative abstract classes and reusable interfaces.
#
# Include this module in a class to install the class DSL documented below.
# The instance-method entries on this page describe methods installed on the
# consuming class, not methods on its instances or on AbstractaContracts itself.
# Contracts check method presence and ownership, not signatures or return types.
# Private and protected implementations count as present.
#
# @example Declare and implement a contract
#   class Reader
#     include AbstractaContracts.with_methods(:read)
#   end
#   class FileReader < Reader
#     def read = :contents
#   end
#   FileReader.new.read # => :contents
module AbstractaContracts
  # @!method abstract_class!
  #   Mark only this class explicitly abstract; descendants do not inherit the marker.
  #   @return [Class] self
  #
  # @!method abstract_method(*names)
  #   Declare inherited instance requirements. Redeclaration requires a fresh implementation.
  #   @return [Class] self
  #   @param names [Array<String, Symbol, Array>] names to flatten and deduplicate
  #   @raise [AbstractaContracts::Error] for invalid method names
  #
  # @!method abstract_class_method(*names)
  #   Declare inherited class requirements. Redeclaration requires a fresh implementation.
  #   @return [Class] self
  #   @param names [Array<String, Symbol, Array>] names to flatten and deduplicate
  #   @raise [AbstractaContracts::Error] for invalid method names
  #
  # @!method implements(*interfaces)
  #   Register interfaces and include their modules. Repeated registrations are deduplicated.
  #   @return [Class] self
  #   @param interfaces [Array<Module, Array>] interface modules, optionally nested
  #   @raise [AbstractaContracts::Error] if any module is not an interface
  #
  # @!method explicitly_abstract?
  #   Whether this class itself was marked explicitly abstract.
  #   @return [Boolean]
  #
  # @!method abstract?
  #   Whether explicitly abstract or missing any abstract or interface requirement.
  #   @return [Boolean]
  #
  # @!method concrete?
  #   Whether this class can pass contract validation.
  #   @return [Boolean]
  #
  # @!method valid_implementation?
  #   Whether this class is concrete, including its explicit abstract marker.
  #   @return [Boolean]
  #
  # @!method validate_implementation!
  #   Validate all requirements and the explicit abstract marker without constructing an instance.
  #   @return [true] when concrete
  #   @raise [AbstractaContracts::Error] if methods are missing or the class is explicitly abstract
  #
  # @!method abstract_methods
  #   Required abstract instance names, including inherited declarations.
  #   @return [Array<Symbol>] frozen names
  #
  # @!method abstract_class_methods
  #   Required abstract class names, including inherited declarations.
  #   @return [Array<Symbol>] frozen names
  #
  # @!method direct_interfaces
  #   Interfaces registered directly on this class.
  #   @return [Array<Module>] frozen snapshot
  #
  # @!method interfaces
  #   Registered interfaces including class inheritance and interface ancestry.
  #   @return [Array<Module>] deduplicated frozen snapshot
  #
  # @!method implements?(interface)
  #   Whether an interface occurs in the complete registered interface hierarchy.
  #   @return [Boolean]
  #   @param interface [Module] an interface module
  #   @raise [AbstractaContracts::Error] if the argument is not an interface
  #
  # @!method interface_methods
  #   Required instance names from all registered interfaces.
  #   @return [Array<Symbol>] deduplicated frozen names
  #
  # @!method interface_class_methods
  #   Required class names from all registered interfaces.
  #   @return [Array<Symbol>] deduplicated frozen names
  #
  # @!method missing_abstract_methods
  #   Unresolved abstract instance requirements.
  #   @return [Array<Symbol>] frozen names
  #
  # @!method missing_abstract_class_methods
  #   Unresolved abstract class requirements.
  #   @return [Array<Symbol>] frozen names
  #
  # @!method missing_interface_methods
  #   Unresolved interface instance requirements.
  #   @return [Array<Symbol>] frozen names
  #
  # @!method missing_interface_class_methods
  #   Unresolved interface class requirements.
  #   @return [Array<Symbol>] frozen names
  #
  # @!method missing_methods
  #   Unresolved combined abstract and interface instance requirements.
  #   @return [Array<Symbol>] frozen names
  #
  # @!method missing_class_methods
  #   Unresolved combined abstract and interface class requirements.
  #   @return [Array<Symbol>] frozen names
  #
  # @private
  MUTEX_CREATION_LOCK = Mutex.new
  private_constant :MUTEX_CREATION_LOCK

  class << self
    # @private
    def included(base)
      install(base)
    end

    # Build a reusable abstract contract for inclusion in classes.
    # Names are flattened, converted to symbols, and deduplicated. Requirements
    # are inherited; redeclarations require an implementation at or below the
    # new declaration in the method lookup chain.
    # @param methods [Array<String, Symbol, Array>] instance method names
    # @param class_methods [Array<String, Symbol>] class method names
    # @return [Module] reusable contract; include it in each consuming class
    # @raise [ArgumentError] if both lists are empty
    # @raise [AbstractaContracts::Error] if a name is neither a string nor a symbol,
    #   is empty, or contains whitespace
    # @raise [TypeError] when the returned contract is included in a module
    def with_methods(*methods, class_methods: [])
      instance_methods = normalize_method_names(methods)
      singleton_methods = normalize_method_names(Array(class_methods))

      if instance_methods.empty? && singleton_methods.empty?
        raise ArgumentError, "at least one abstract instance or class method is required"
      end

      Internal::Contract.new(instance_methods: instance_methods, class_methods: singleton_methods)
    end

    # Build an interface definition for inclusion in a module.
    # Include the result once in a module, then use the class DSL's implements
    # method to register that module. Interfaces may include other interfaces
    # and supply default instance methods. Inherited implementations also count.
    # @param methods [Array<String, Symbol, Array>] instance method names
    # @param class_methods [Array<String, Symbol>] class method names
    # @return [Module] definition to include in an interface module
    # @raise [ArgumentError] if both lists are empty
    # @raise [AbstractaContracts::Error] for invalid names or repeated definition
    # @raise [TypeError] when the definition is included in a class
    # @example Define and implement an interface
    #   readable = Module.new { include AbstractaContracts.interface(:read) }
    #   reader = Class.new do
    #     include AbstractaContracts
    #     implements readable
    #     def read = :contents
    #   end
    #   reader.new.read # => :contents
    def interface(*methods, class_methods: [])
      instance_methods = normalize_method_names(methods)
      singleton_methods = normalize_method_names(Array(class_methods))

      if instance_methods.empty? && singleton_methods.empty?
        raise ArgumentError, "at least one interface instance or class method is required"
      end

      Internal::Interface.new(instance_methods: instance_methods, class_methods: singleton_methods)
    end

    # @private
    def install(base)
      raise TypeError, "AbstractaContracts can only be included in classes" unless base.is_a?(Class)

      base.extend(Internal::ClassMethods) unless base.singleton_class < Internal::ClassMethods
      base.singleton_class.prepend(Internal::ConstructorGuard) unless base.singleton_class < Internal::ConstructorGuard
      mutex_for(base)
      base
    end

    # @private
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

    # @private
    def interface?(object)
      object.is_a?(Module) && object.respond_to?(:interface?) && object.interface?
    end

    # @private
    def validate_interface!(interface)
      return interface if interface?(interface)

      raise Internal::InvalidInterfaceError, "#{interface.inspect} is not an AbstractaContracts interface"
    end

    # @private
    def normalize_interfaces(interfaces)
      interfaces.flatten.map { |interface| validate_interface!(interface) }.uniq.freeze
    end

    # @private
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

    # @private
    def register_instance_methods(base, names)
      install(base)
      synchronize(base) do
        declared = base.send(:abstracta_contracts_declared_instance_methods)
        names.each { |name| declared << name unless declared.include?(name) }
      end
    end

    # @private
    def register_class_methods(base, names)
      install(base)
      synchronize(base) do
        declared = base.send(:abstracta_contracts_declared_class_methods)
        names.each { |name| declared << name unless declared.include?(name) }
      end
    end

    # @private
    def required_instance_methods_for(klass)
      required_methods_for(klass, :abstracta_contracts_declared_instance_methods)
    end

    # @private
    def required_class_methods_for(klass)
      required_methods_for(klass, :abstracta_contracts_declared_class_methods)
    end

    # @private
    def missing_instance_methods_for(klass)
      required_instance_methods_for(klass).filter_map do |name, declaration_owner|
        name unless implemented_after_declaration?(klass, name, declaration_owner, singleton: false)
      end
    end

    # @private
    def missing_class_methods_for(klass)
      required_class_methods_for(klass).filter_map do |name, declaration_owner|
        name unless implemented_after_declaration?(klass, name, declaration_owner, singleton: true)
      end
    end

    # @private
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

    # @private
    def interface_instance_methods_for(interface)
      validate_interface!(interface)
      interface_hierarchy(interface).flat_map do |candidate|
        candidate.instance_variable_get(:@abstracta_contracts_interface_instance_methods) || []
      end.uniq.freeze
    end

    # @private
    def interface_class_methods_for(interface)
      validate_interface!(interface)
      interface_hierarchy(interface).flat_map do |candidate|
        candidate.instance_variable_get(:@abstracta_contracts_interface_class_methods) || []
      end.uniq.freeze
    end

    # @private
    def required_interface_instance_methods_for(klass)
      interfaces_for(klass).flat_map { |interface| interface_instance_methods_for(interface) }.uniq
    end

    # @private
    def required_interface_class_methods_for(klass)
      interfaces_for(klass).flat_map { |interface| interface_class_methods_for(interface) }.uniq
    end

    # @private
    def missing_interface_instance_methods_for(klass)
      required_interface_instance_methods_for(klass).reject do |name|
        method_available?(klass, name, singleton: false)
      end
    end

    # @private
    def missing_interface_class_methods_for(klass)
      required_interface_class_methods_for(klass).reject do |name|
        method_available?(klass, name, singleton: true)
      end
    end

    # @private
    def synchronize(base, &)
      mutex_for(base).synchronize(&)
    end

    # @private
    def class_name(klass)
      klass.name || klass.inspect
    end

    # @private
    def interface_name(interface)
      interface.name || interface.inspect
    end

    private

    # @private
    def mutex_for(base)
      if base.instance_variable_defined?(:@abstracta_contracts_mutex)
        return base.instance_variable_get(:@abstracta_contracts_mutex)
      end

      MUTEX_CREATION_LOCK.synchronize do
        base.instance_variable_get(:@abstracta_contracts_mutex) ||
          base.instance_variable_set(:@abstracta_contracts_mutex, Mutex.new)
      end
    end

    # @private
    def required_methods_for(klass, reader)
      declarations = {}

      klass.ancestors.reverse_each do |ancestor|
        next unless ancestor.is_a?(Class)
        next unless ancestor.respond_to?(reader, true)

        ancestor.send(reader).each { |name| declarations[name] = ancestor }
      end

      declarations.freeze
    end

    # @private
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

    # @private
    def method_available?(klass, name, singleton:)
      lookup = singleton ? klass.singleton_class : klass
      lookup.instance_method(name)
      true
    rescue NameError
      false
    end

    # @private
    def interface_hierarchy(interface)
      validate_interface!(interface)

      interface.ancestors.reverse_each.with_object([]) do |ancestor, result|
        next unless interface?(ancestor)

        result << ancestor unless result.include?(ancestor)
      end
    end
  end
end
