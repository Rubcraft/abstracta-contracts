# frozen_string_literal: true

RSpec.describe "AbstractaContracts public API" do
  it "keeps implementation constants behind Internal" do
    expect(AbstractaContracts.const_defined?(:Error, false)).to be(true)
    expect(AbstractaContracts.const_defined?(:VERSION, false)).to be(true)
    expect(AbstractaContracts.const_defined?(:Internal, false)).to be(true)

    expect(AbstractaContracts.const_defined?(:Contract, false)).to be(false)
    expect(AbstractaContracts.const_defined?(:Interface, false)).to be(false)
    expect(AbstractaContracts.const_defined?(:ClassMethods, false)).to be(false)
    expect(AbstractaContracts.const_defined?(:ConstructorGuard, false)).to be(false)
    expect(Object.const_defined?(:Abstracta, false)).to be(false)
  end

  it "uses AbstractaContracts::Error as the supported rescue boundary" do
    base = Class.new do
      include AbstractaContracts.with_methods(:run)
    end

    expect { base.new }.to raise_error(AbstractaContracts::Error, /#run/)
  end
end
