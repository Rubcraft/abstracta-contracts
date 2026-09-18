# Changelog

All notable changes to AbstractaContracts will be documented in this file.

## Unreleased

### Added

- Added Bundler Audit dependency checks to the CI workflow.

## [0.1.1] - 2026-09-08

### Added

- Public YARD reference, generation task, and documentation check in CI.

### Changed

- Group interface specs by definition, implementation, inheritance, and introspection.
- Make each spec explicitly load its helper for standalone execution.
- Correct the reusable-contract README example to preserve local variable scope.

## [0.1.0] - 2026-09-04

### Added

- Declarative abstract classes with `AbstractaContracts.with_methods`.
- Explicit abstract class, instance-method, and class-method contracts.
- Reusable interfaces with `AbstractaContracts.interface` and `implements`.
- Inherited and composable contracts across class and interface hierarchies.
- Runtime instantiation validation and contract introspection.
- Private implementation namespace under `AbstractaContracts::Internal`.
- RSpec, RuboCop, branch-aware SimpleCov thresholds, CI matrix, Dependabot, and Trusted Publishing release verification.
