# flayyer-ruby

This gem is agnostic to any Ruby framework and has zero external dependencies.

To create a FLAYYER template please refer to: [flayyer.com](https://flayyer.com?ref=flayyer-ruby)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'flayyer'
```

And then execute:

```sh
bundle install
```

Or install it yourself as:

```sh
gem install flayyer
```

## Usage

After installing the gem you can format URL as:

```ruby
require 'flayyer'

flayyer = Flayyer::FlayyerURL.create do |f|
  f.tenant = 'tenant'
  f.deck = 'deck'
  f.template = 'template'
  f.variables = {
      title: 'Hello world!'
  }
end

# Use this image in your <head/> tags
url = flayyer.href
# > https://flayyer.io/v2/tenant/deck/template.jpeg?__v=1596906866&title=Hello+world%21
```

Variables can be complex arrays and hashes.

```ruby
flayyer = Flayyer::FlayyerURL.create do |f|
  # ...
  f.variables = {
      items: [
          { text: 'Oranges', count: 12 },
          { text: 'Apples', count: 14 },
      ],
  }
  f.meta = {
    id: 'slug-or-id', # To identify the resource in our analytics report
  }
end
```

**IMPORTANT: variables must be serializable.**

To decode the URL for debugging purposes:

```ruby
print(CGI.unescape(url))
# > https://flayyer.io/v2/tenant/deck/template.jpeg?title=Hello+world!&__v=123
```

## Ruby on Rails

Ruby on Rails will try to safely render strings into the HTML. Any FLAYYER string is already safe-serialized and should not be serialized again.

To prevent double serialization make sure to call `.html_safe` like this:

```ruby
url = flayyer.href.html_safe
```

> https://apidock.com/rails/String/html_safe

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/flayyer/flayyer-ruby.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
