# token_attr

Unique random token generator for ActiveRecord.

## Installation

Add `token_attr` to your Gemfile:

    gem 'token_attr', '~> 0.1.0'

## Usage

```
class User < ActiveRecord::Base
  include TokenAttr
  token_attr :token
end

user = User.new
user.valid?
user.token # => "b8bd30ff"
```

The token is generated in a `before_validation` callback.

### Options

#### Length

The length of the token to generate.

Default: 8

```
token_attr :token, length: 40
```

#### Alphabet

The alphabet to use to generate the token.

Uses hexadecimal characters by default.

Accepted values:
- `:alphabetic` - any character from a to z (both lower and upper case)
- `:numeric` - any number
- `:alphanumeric` - any character or number
- a string - a string of your choice of the characters you want to use

```
token_attr :token, alphabet: :numeric # => "82051173"
token_attr :token, alphabet: :alphabetic # => "xqnInSJa"
token_attr :token, alphabet: :alphanumeric # => "61nD0lUo"
token_attr :token, alphabet: "token" # => "ktnekoet"
```

## Contributing

1. Fork it ( http://github.com/mbillard/token_attr/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
