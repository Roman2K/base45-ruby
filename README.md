# Base45

Ruby Base45 enc-/decoding library based on the following implementations:

* https://github.com/ehn-dcc-development/base45-swift
* https://github.com/opendevtools/base45

## Usage

`Gemfile`:

```ruby
gem 'base45-ruby', github: 'Roman2K/base45-ruby'
```

API:

```ruby
require 'base45'

s = Base45.encode "Hello"
s = Base45.decode s  # => "Hello"
```
