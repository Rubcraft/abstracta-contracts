# frozen_string_literal: true

require "simplecov"

SimpleCov.configure do
  skip "/spec/"
  skip "/vendor/"

  group "Core", "lib/abstracta_contracts.rb"
  group "Components", "lib/abstracta_contracts"

  cover "lib/**/*.rb"

  enable_coverage :branch

  minimum_coverage line: 95, branch: 90
end
