# frozen_string_literal: true

RSpec.describe AbstractaContracts do
  describe ".with_methods" do
    it "declares abstract instance methods and prevents incomplete instantiation" do
      base = Class.new do
        include AbstractaContracts.with_methods(:enabled?, :features)
      end

      expect(base).to be_abstract
      expect(base.abstract_methods).to eq(%i[enabled? features])
      expect(base.missing_abstract_methods).to eq(%i[enabled? features])
      expect { base.new }.to raise_error(AbstractaContracts::Error, /#enabled\?, #features/)
    end

    it "allows a descendant to become concrete by implementing the full contract" do
      base = Class.new do
        include AbstractaContracts.with_methods(:enabled?, :features)
      end

      implementation = Class.new(base) do
        def enabled?(_feature) = true
        def features = [:search]
      end

      expect(implementation).to be_concrete
      expect(implementation.missing_abstract_methods).to be_empty
      expect { implementation.new }.not_to raise_error
    end

    it "supports class method contracts" do
      base = Class.new do
        include AbstractaContracts.with_methods(:call, class_methods: [:provider_name])
      end

      implementation = Class.new(base) do
        def call = :ok
        def self.provider_name = :redis
      end

      expect(base.abstract_class_methods).to eq([:provider_name])
      expect(implementation).to be_concrete
    end

    it "rejects an empty contract" do
      expect { described_class.with_methods }.to raise_error(ArgumentError, /at least one/)
    end

    it "rejects invalid method names" do
      expect { described_class.with_methods(Object.new) }
        .to raise_error(AbstractaContracts::Error)
      expect { described_class.with_methods("not valid") }
        .to raise_error(AbstractaContracts::Error)
    end

    it "rejects inclusion in modules" do
      expect { Module.new { include AbstractaContracts } }.to raise_error(TypeError)
    end
  end

  describe "advanced DSL" do
    it "supports include AbstractaContracts with explicit declarations" do
      base = Class.new do
        include AbstractaContracts

        abstract_class!
        abstract_method :read
        abstract_class_method :kind
      end

      expect(base).to be_explicitly_abstract
      expect(base.abstract_methods).to eq([:read])
      expect(base.abstract_class_methods).to eq([:kind])
    end

    it "supports explicit abstract class method declarations" do
      base = Class.new do
        include AbstractaContracts

        abstract_class_method :kind
      end

      expect(base.abstract_class_methods).to eq([:kind])
    end

    it "deduplicates repeated declarations" do
      base = Class.new do
        include AbstractaContracts

        abstract_method :read, :read
        abstract_method :read
        abstract_class_method :kind, :kind
        abstract_class_method :kind
      end

      expect(base.abstract_methods).to eq([:read])
      expect(base.abstract_class_methods).to eq([:kind])
    end
  end
end
