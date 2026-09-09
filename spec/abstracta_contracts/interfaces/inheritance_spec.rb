# frozen_string_literal: true

require "spec_helper"

RSpec.describe "AbstractaContracts interface inheritance" do
  let(:cacheable) do
    Module.new do
      include AbstractaContracts.interface(:read, :write, class_methods: [:adapter_name])
    end
  end

  it "inherits implemented interfaces through class inheritance" do
    interface = cacheable

    base = Class.new do
      include AbstractaContracts

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
      include AbstractaContracts.interface(:read, :write)

      def read = :default
    end

    implementation = Class.new do
      include AbstractaContracts

      implements interface

      def write = :ok
    end

    expect(implementation.new.read).to eq(:default)
    expect(implementation).to be_concrete
  end

  it "supports interface inheritance" do
    readable = Module.new do
      include AbstractaContracts.interface(:read)
    end

    cache = Module.new do
      include readable
      include AbstractaContracts.interface(:write)
    end

    implementation = Class.new do
      include AbstractaContracts

      implements cache

      def read = :ok
      def write = :ok
    end

    expect(cache.interface_methods).to contain_exactly(:read, :write)
    expect(implementation.interfaces).to contain_exactly(readable, cache)
    expect(implementation).to be_concrete
  end
end
