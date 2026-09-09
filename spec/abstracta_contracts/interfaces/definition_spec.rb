# frozen_string_literal: true

require "spec_helper"

RSpec.describe "AbstractaContracts interface definition" do
  let(:cacheable) do
    Module.new do
      include AbstractaContracts.interface(:read, :write, class_methods: [:adapter_name])
    end
  end

  it "defines a pure interface without making the module an abstract class" do
    expect(cacheable).to be_interface
    expect(cacheable.interface_methods).to eq(%i[read write])
    expect(cacheable.interface_class_methods).to eq([:adapter_name])
  end

  it "rejects an empty interface" do
    expect { AbstractaContracts.interface }.to raise_error(ArgumentError, /at least one/)
  end

  it "rejects including an interface definition in a class" do
    expect { Class.new { include AbstractaContracts.interface(:read) } }.to raise_error(TypeError)
  end

  it "rejects defining the same interface module twice" do
    interface = Module.new { include AbstractaContracts.interface(:read) }

    expect { interface.include(AbstractaContracts.interface(:write)) }
      .to raise_error(AbstractaContracts::Error, /already an AbstractaContracts interface/)
  end
end
