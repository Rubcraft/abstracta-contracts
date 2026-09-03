# frozen_string_literal: true

RSpec.describe "Abstracta errors" do
  it "raises a dedicated error for explicitly abstract classes without missing methods" do
    base = Class.new do
      include Abstracta
      abstract_class!
    end

    expect { base.new }.to raise_error(Abstracta::Error, /is abstract/)
  end

  it "includes both instance and class methods in incomplete implementation errors" do
    base = Class.new do
      include Abstracta.with_methods(:run, class_methods: [:kind])
    end

    expect { base.new }
      .to raise_error(Abstracta::Error, /#run.*\.kind/)
  end
end
