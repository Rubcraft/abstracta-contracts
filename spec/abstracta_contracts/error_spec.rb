# frozen_string_literal: true

RSpec.describe "AbstractaContracts errors" do
  it "raises a dedicated error for explicitly abstract classes without missing methods" do
    base = Class.new do
      include AbstractaContracts

      abstract_class!
    end

    expect { base.new }.to raise_error(AbstractaContracts::Error, /is abstract/)
  end

  it "includes both instance and class methods in incomplete implementation errors" do
    base = Class.new do
      include AbstractaContracts.with_methods(:run, class_methods: [:kind])
    end

    expect { base.new }
      .to raise_error(AbstractaContracts::Error, /#run.*\.kind/)
  end

  it "describes class-only incomplete implementations" do
    base = Class.new do
      include AbstractaContracts.with_methods(class_methods: [:kind])
    end

    expect { base.new }.to raise_error(AbstractaContracts::Error, /\.kind/)
  end
end
