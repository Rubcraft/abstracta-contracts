# frozen_string_literal: true

RSpec.describe "Abstracta public API" do
  it "keeps implementation constants behind Internal" do
    expect(Abstracta.const_defined?(:Error, false)).to be(true)
    expect(Abstracta.const_defined?(:VERSION, false)).to be(true)
    expect(Abstracta.const_defined?(:Internal, false)).to be(true)

    expect(Abstracta.const_defined?(:Contract, false)).to be(false)
    expect(Abstracta.const_defined?(:Interface, false)).to be(false)
    expect(Abstracta.const_defined?(:ClassMethods, false)).to be(false)
    expect(Abstracta.const_defined?(:ConstructorGuard, false)).to be(false)
  end

  it "uses Abstracta::Error as the supported rescue boundary" do
    base = Class.new do
      include Abstracta.with_methods(:run)
    end

    expect { base.new }.to raise_error(Abstracta::Error, /#run/)
  end
end
