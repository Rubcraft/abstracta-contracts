# frozen_string_literal: true

RSpec.describe "Abstracta inheritance" do
  it "accumulates contracts through multiple inheritance levels" do
    a = Class.new do
      include Abstracta.with_methods(:foo, :bar)
    end

    b = Class.new(a) do
      abstract_method :baz
      def foo = :foo
    end

    c = Class.new(b) do
      def bar = :bar
      def baz = :baz
    end

    expect(a.missing_abstract_methods).to contain_exactly(:foo, :bar)
    expect(b.missing_abstract_methods).to contain_exactly(:bar, :baz)
    expect(c.missing_abstract_methods).to be_empty
    expect(c).to be_concrete
  end

  it "requires a fresh implementation when a descendant redeclares a method abstract" do
    a = Class.new do
      include Abstracta.with_methods(:call)
    end

    b = Class.new(a) do
      def call = :b
    end

    c = Class.new(b) do
      abstract_method :call
    end

    d = Class.new(c) do
      def call = :d
    end

    expect(b).to be_concrete
    expect(c.missing_abstract_methods).to eq([:call])
    expect(d).to be_concrete
  end

  it "accepts implementations supplied by modules included below the declaration" do
    contract = Module.new do
      def call = :module
    end

    base = Class.new do
      include Abstracta.with_methods(:call)
    end

    implementation = Class.new(base) do
      include contract
    end

    expect(implementation).to be_concrete
  end

  it "does not treat a module implementation above the abstract declaration as fulfilling it" do
    implementation_module = Module.new do
      def call = :module
    end

    base = Class.new do
      include implementation_module
      include Abstracta.with_methods(:call)
    end

    expect(base.missing_abstract_methods).to eq([:call])
  end

  it "does not inherit the explicit abstract marker" do
    base = Class.new do
      include Abstracta

      abstract_class!
    end

    child = Class.new(base)

    expect(base).to be_abstract
    expect(child).to be_concrete
    expect { child.new }.not_to raise_error
  end
end
