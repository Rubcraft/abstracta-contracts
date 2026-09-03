# Contributing

Keep the public API small, explicit, dependency-free, and compatible with supported Ruby versions.

Before proposing a behavioral change:

1. Add or update specs for the behavior.
2. Run `bundle exec rake`.
3. Update public documentation when the API changes.
4. Avoid compatibility shims for APIs that have never been publicly released.

Repository and version-control orchestration are outside this gem's responsibilities.
