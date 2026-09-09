# Contributing

Keep the public API small, explicit, dependency-free, and compatible with supported Ruby versions.

Before proposing a behavioral change:

1. Add or update specs for the behavior.
2. Run `bundle exec rake`.
3. Update public documentation when the API changes.
4. Avoid compatibility shims for APIs that have never been publicly released.

Repository and version-control orchestration are outside this gem's responsibilities.

## API documentation and spec organization

Document supported factories and the installed class DSL with YARD. The DSL
is listed on AbstractaContracts as virtual instance methods for documentation;
these methods run on consuming classes. Keep Internal implementation objects
out of the public reference. Run `bundle exec rake yard`; warnings fail the task.

Group specs by behavior: contract declarations, reusable contracts, inheritance,
visibility, introspection, errors, and public API boundaries. Interface specs
live under `spec/abstracta_contracts/interfaces/`, split into definition,
implementation, inheritance, and introspection. Put edge cases alongside their
behavior, not in coverage-only files. Keep setup local unless sharing it makes
the contract clearer. Every spec file must run independently.

Run `COVERAGE=true bundle exec rspec`, `bundle exec rubocop`, and
`bundle exec rake yard build` before submitting. Coverage minimums remain
95% lines and 90% branches. The CI Ruby matrix verifies supported runtimes;
local validation should state which Ruby version was used.
