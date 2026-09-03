# frozen_string_literal: true

RSpec.describe "Abstracta reusable contracts" do
  it "can be reused by independent classes" do
    contract = Abstracta.with_methods(:read, :write)

    first = Class.new do
      include contract
      def read = :first
      def write = :first
    end

    second = Class.new do
      include contract
      def read = :second
      def write = :second
    end

    expect(first).to be_concrete
    expect(second).to be_concrete
  end

  it "accepts instance and class methods implemented by the declaring class" do
    implementation = Class.new do
      include Abstracta.with_methods(:read, class_methods: [:adapter_name])

      def read = :ok
      def self.adapter_name = :memory
    end

    expect(implementation).to be_concrete
  end
end
