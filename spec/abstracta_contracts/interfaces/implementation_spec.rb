# frozen_string_literal: true

require "spec_helper"

RSpec.describe "AbstractaContracts interface implementation" do
  let(:cacheable) do
    Module.new do
      include AbstractaContracts.interface(:read, :write, class_methods: [:adapter_name])
    end
  end

  it "lets an AbstractaContracts class implement an interface" do
    interface = cacheable

    implementation = Class.new do
      include AbstractaContracts

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
      include AbstractaContracts

      implements interface

      def read = :ok
    end

    expect(implementation.missing_interface_methods).to eq([:write])
    expect(implementation.missing_interface_class_methods).to eq([:adapter_name])
    expect(implementation).to be_abstract
    expect { implementation.new }
      .to raise_error(AbstractaContracts::Error, /#write.*\.adapter_name/)
  end

  it "rejects non-interface modules" do
    ordinary_module = Module.new

    klass = Class.new do
      include AbstractaContracts
    end

    expect { klass.implements ordinary_module }
      .to raise_error(AbstractaContracts::Error)
  end

  it "deduplicates repeated interface implementations" do
    interface = cacheable

    implementation = Class.new do
      include AbstractaContracts

      implements interface
      implements interface
    end

    expect(implementation.direct_interfaces).to eq([interface])
  end
end
