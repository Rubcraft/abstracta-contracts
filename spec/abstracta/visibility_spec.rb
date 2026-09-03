# frozen_string_literal: true

RSpec.describe "Abstracta method visibility" do
  it "allows private instance methods to satisfy a contract" do
    base = Class.new do
      include Abstracta.with_methods(:secret)
    end

    child = Class.new(base) do
      private

      def secret = :ok
    end

    expect(child).to be_concrete
  end

  it "allows private class methods to satisfy a class contract" do
    base = Class.new do
      include Abstracta.with_methods(class_methods: [:secret])
    end

    child = Class.new(base) do
      class << self
        private

        def secret = :ok
      end
    end

    expect(child).to be_concrete
  end
end
