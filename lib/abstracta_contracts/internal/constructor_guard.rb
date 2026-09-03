# frozen_string_literal: true

module AbstractaContracts
  module Internal
    module ConstructorGuard
      def new(...)
        validate_implementation! if respond_to?(:validate_implementation!)
        super
      end
    end
  end
end
