# frozen_string_literal: true

RSpec.describe "Abstracta interfaces" do
  let(:cacheable) do
    Module.new do
      include Abstracta.interface(:read, :write, class_methods: [:adapter_name])
    end
  end

  it "defines a pure interface without making the module an abstract class" do
    expect(cacheable).to be_interface
    expect(cacheable.interface_methods).to eq(%i[read write])
    expect(cacheable.interface_class_methods).to eq([:adapter_name])
  end

  it "rejects an empty interface" do
    expect { Abstracta.interface }.to raise_error(ArgumentError, /at least one/)
  end

  it "rejects including an interface definition in a class" do
    expect { Class.new { include Abstracta.interface(:read) } }.to raise_error(TypeError)
  end

  it "rejects defining the same interface module twice" do
    interface = Module.new { include Abstracta.interface(:read) }

    expect { interface.include(Abstracta.interface(:write)) }
      .to raise_error(Abstracta::Error, /already an Abstracta interface/)
  end

  it "lets an Abstracta class implement an interface" do
    interface = cacheable

    implementation = Class.new do
      include Abstracta

      implements interface

      def read = :ok
      def write = :ok
      def self.adapter_name = :memory
    end

    expect(implementation.implements?(cacheable)).to be(true)
    expect(implementation.interfaces).to eq([cacheable])
    expect(implementation.missing_interface_methods).to be_empty
    expect(implementation.missing_interface_class_methods).to be_empty
    expect(implementation).to be_concrete
    expect { implementation.new }.not_to raise_error
  end

  it "prevents instantiation while interface methods are missing" do
    interface = cacheable

    implementation = Class.new do
      include Abstracta

      implements interface

      def read = :ok
    end

    expect(implementation.missing_interface_methods).to eq([:write])
    expect(implementation.missing_interface_class_methods).to eq([:adapter_name])
    expect(implementation).to be_abstract
    expect { implementation.new }
      .to raise_error(Abstracta::Error, /#write.*\.adapter_name/)
  end

  it "inherits implemented interfaces through class inheritance" do
    interface = cacheable

    base = Class.new do
      include Abstracta

      implements interface
    end

    implementation = Class.new(base) do
      def read = :ok
      def write = :ok
      def self.adapter_name = :memory
    end

    expect(implementation.interfaces).to eq([cacheable])
    expect(implementation).to be_concrete
  end

  it "accepts default instance methods supplied by the interface module" do
    interface = Module.new do
      include Abstracta.interface(:read, :write)

      def read = :default
    end

    implementation = Class.new do
      include Abstracta

      implements interface

      def write = :ok
    end

    expect(implementation.new.read).to eq(:default)
    expect(implementation).to be_concrete
  end

  it "supports interface inheritance" do
    readable = Module.new do
      include Abstracta.interface(:read)
    end

    cache = Module.new do
      include readable
      include Abstracta.interface(:write)
    end

    implementation = Class.new do
      include Abstracta

      implements cache

      def read = :ok
      def write = :ok
    end

    expect(cache.interface_methods).to contain_exactly(:read, :write)
    expect(implementation.interfaces).to contain_exactly(readable, cache)
    expect(implementation).to be_concrete
  end

  it "rejects non-interface modules" do
    ordinary_module = Module.new

    klass = Class.new do
      include Abstracta
    end

    expect { klass.implements ordinary_module }
      .to raise_error(Abstracta::Error)
  end

  it "does not monkey patch Class with implements" do
    expect(Class.method_defined?(:implements)).to be(false)
  end

  it "deduplicates repeated interface implementations" do
    interface = cacheable

    implementation = Class.new do
      include Abstracta

      implements interface
      implements interface
    end

    expect(implementation.direct_interfaces).to eq([interface])
  end
end
