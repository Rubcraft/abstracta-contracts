# Abstracta Contracts

## Public API

AbstractaContracts exposes one supported entry point:

```ruby
require "abstracta_contracts"
```

The supported root API is intentionally small:

- `AbstractaContracts.with_methods`
- `AbstractaContracts.interface`
- `AbstractaContracts::Error`
- `AbstractaContracts::VERSION`
- the class DSL installed by `include AbstractaContracts`: `abstract_class!`, `abstract_method`, `abstract_class_method`, and `implements`
- the documented introspection methods installed by `include AbstractaContracts`

Implementation modules, contract objects, guards, and specialized errors live behind `AbstractaContracts::Internal` and are not public API. No pre-release compatibility entry points are shipped.


Declarative abstract classes and interfaces for Ruby.

> **Gem:** `abstracta-contracts`  
> **Namespace:** `AbstractaContracts`

## Installation

```ruby
gem "abstracta-contracts", require: "abstracta_contracts"
```

```ruby
require "abstracta_contracts"
```

## Abstract classes

The compact API is the recommended form:

```ruby
class FeatureProvider
  include AbstractaContracts.with_methods(:enabled?, :features)
end
```

A class with an incomplete contract cannot be instantiated. A descendant becomes concrete when it implements every required method.

```ruby
class RedisProvider < FeatureProvider
  def enabled?(feature)
    features.include?(feature)
  end

  def features
    [:search, :reports]
  end
end
```

Class-method contracts use `class_methods:`:

```ruby
class Provider
  include AbstractaContracts.with_methods(:call, class_methods: [:provider_name])
end
```

For dynamic or incremental declarations, use the explicit DSL:

```ruby
class Provider
  include AbstractaContracts

  abstract_class!
  abstract_method :enabled?
  abstract_method :features
  abstract_class_method :provider_name
end
```

`abstract_class!` marks only the declaring class as explicitly abstract. The marker is not inherited. Method requirements are inherited and can be extended or redeclared by descendants.

## Reusable abstract contracts

`with_methods` returns a reusable module-like contract:

```ruby
cache_contract = AbstractaContracts.with_methods(:read, :write, :delete)

class RedisCache
  include cache_contract

  def read(key) = nil
  def write(key, value) = value
  def delete(key) = nil
end
```

## Interfaces

Interfaces are separate from abstract classes:

```ruby
module Cacheable
  include AbstractaContracts.interface(
    :read,
    :write,
    :delete,
    class_methods: [:adapter_name]
  )
end
```

Classes opt into AbstractaContracts and explicitly declare interfaces:

```ruby
class RedisCache
  include AbstractaContracts
  implements Cacheable

  def read(key) = nil
  def write(key, value) = value
  def delete(key) = nil
  def self.adapter_name = :redis
end
```

AbstractaContracts deliberately does not add `implements` to every Ruby class.

### Interface inheritance and defaults

An interface may include another AbstractaContracts interface. Interface modules may also provide default instance methods; those methods satisfy their requirements.

```ruby
module Readable
  include AbstractaContracts.interface(:read)
end

module Cacheable
  include Readable
  include AbstractaContracts.interface(:write)

  def read(key) = nil
end
```

## Introspection

Abstract classes expose:

```ruby
Provider.abstract?
Provider.concrete?
Provider.explicitly_abstract?
Provider.abstract_methods
Provider.abstract_class_methods
Provider.missing_abstract_methods
Provider.missing_abstract_class_methods
Provider.valid_implementation?
Provider.validate_implementation!
```

Classes implementing interfaces also expose:

```ruby
RedisCache.interfaces
RedisCache.direct_interfaces
RedisCache.implements?(Cacheable)
RedisCache.interface_methods
RedisCache.interface_class_methods
RedisCache.missing_interface_methods
RedisCache.missing_interface_class_methods
```

`missing_methods` and `missing_class_methods` return the combined unresolved abstract-class and interface requirements.

## Contract rules

- Abstract method contracts accumulate through inheritance.
- Redeclaring a method as abstract requires a fresh implementation below that declaration.
- Private and protected methods can satisfy contracts.
- Modules included below an abstract declaration can satisfy instance-method contracts.
- Interfaces remain distinct from abstract classes.
- Interface requirements can be satisfied by the class, inherited implementations, or interface defaults.
- AbstractaContracts has no runtime dependencies.

## Development

```bash
bundle install
bundle exec rake
bundle exec gem build abstracta-contracts.gemspec
```

## Release

The repository includes CI and a RubyGems Trusted Publishing workflow. Repository synchronization, branches, commits, tags, and other version-control operations are intentionally outside the gem's responsibilities.

## License

MIT.
