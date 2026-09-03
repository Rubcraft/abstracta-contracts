# frozen_string_literal: true

require_relative "lib/abstracta/version"

Gem::Specification.new do |spec|
  spec.name = "abstracta-contracts"
  spec.version = Abstracta::VERSION
  spec.authors = ["Juan Furattini"]
  spec.email = []

  spec.summary = "Declarative abstract classes, interfaces, and method contracts for Ruby."
  spec.description = <<~DESCRIPTION
    Abstracta provides lightweight, dependency-free abstract class contracts for Ruby,
    including declarative instance/class methods, reusable interfaces, inherited contracts,
    runtime validation, and introspection.
  DESCRIPTION
  spec.homepage = "https://github.com/Rubcraft/abstracta-contracts"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/Rubcraft/abstracta-contracts"
  spec.metadata["changelog_uri"] = "https://github.com/Rubcraft/abstracta-contracts/blob/main/CHANGELOG.md"
  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(__dir__) do
    Dir["lib/**/*", "LICENSE.txt", "README.md", "CHANGELOG.md"]
  end
  spec.require_paths = ["lib"]
end
