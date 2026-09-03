# frozen_string_literal: true

RSpec.describe "AbstractaContracts introspection" do
  let(:base) do
    Class.new do
      include AbstractaContracts.with_methods(:read, :write, class_methods: [:adapter_name])
    end
  end

  it "reports required and missing methods separately" do
    child = Class.new(base) do
      def read = :ok
      def self.adapter_name = :memory
    end

    expect(child.abstract_methods).to eq(%i[read write])
    expect(child.abstract_class_methods).to eq([:adapter_name])
    expect(child.missing_abstract_methods).to eq([:write])
    expect(child.missing_abstract_class_methods).to be_empty
    expect(child.valid_implementation?).to be(false)
  end

  it "can validate an implementation explicitly" do
    child = Class.new(base) do
      def read = :ok
    end

    expect { child.validate_implementation! }
      .to raise_error(AbstractaContracts::Error, /#write.*\.adapter_name/)
  end

  it "returns true when explicit validation succeeds" do
    child = Class.new(base) do
      def read = :ok
      def write = :ok
      def self.adapter_name = :memory
    end

    expect(child.validate_implementation!).to be(true)
  end
end
