# flayyer-ruby

The AI-powered preview system built from your website (no effort required).

![Flayyer live image](https://github.com/flayyer/create-flayyer-app/blob/master/.github/assets/website-to-preview.png?raw=true&v=1)

**This gem is agnostic to any Ruby framework.**

## Index

- [Get started (5 minutes)](#get-started-5-minutes)
- [Advanced usage](#advanced-usage)
- [Flayyer.io](#flayyerio)
- [Development](#development)
- [Test](#test)

## Get started (5 minutes)

Haven't registered your website yet? Go to [Flayyer.com](https://flayyer.com?ref=flayyer-ruby) and create a project (e.g. `website-com`).

### 1. Install the library

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

### 2. Get your Flayyer.ai smart image link

In your website code (e.g. your landing or product/post view file), set the following:

```ruby
flayyer = Flayyer::FlayyerAI.create do |f|
  # Your project slug
  f.project = 'website-com'
  # The current path of your website
  f.path = '/path/to/product' # In Ruby on Rails you can use `request.env['PATH_INFO']`
end

# Check:
puts flayyer.href
# > https://flayyer.ai/v2/website-com/_/__v=1618281823/path/to/product
```

### 3. Put your smart image link in your `<head>` tags

You'll get the best results like this:

```ruby
# .haml
%meta{ property: 'og:image', content: flayyer.href }
%meta{ name: 'twitter:image', content: flayyer.href }
%meta{ name: 'twitter:card', content: 'summary_large_image' }

# .erb
<meta property="og:image" content='<%= flayyer.href %>'>
<meta name="twitter:image" content='<%= flayyer.href %>'>
<meta name="twitter:card" content="summary_large_image">

# IMPORTANT: if you're using Ruby on Rails, please use `flayyer.href.html_safe` to prevent double serialization
```

### 4. Create a `rule` for your project

Login at [Flayyer.com](https://flayyer.com?ref=flayyer-ruby) > Go to your Dashboard > Manage rules and create a rule like the following:

[![Flayyer basic rule example](https://github.com/flayyer/create-flayyer-app/blob/master/.github/assets/rule-example.png?raw=true&v=1)](https://flayyer.com/dashboard)

Voilà!

## Advanced usage

Advanced features include:

- Custom variables: additional information for your preview that is not present in your website. [Note: if you need customization you should take a look at [Flayyer.io](#flayyerio)]
- Custom metadata: set custom width, height, resolution, and more (see example).
- Signed URLs.

Here you have a detailed full example for project `website-com` and path `/path/to/product`.

```ruby
flayyer = Flayyer::FlayyerAI.create do |f|
  # [Required] Your project slug, find it in your dashboard https://flayyer.com/dashboard/.
  f.project = 'website-com'
  # [Recommended] The current path of your website (by default it's `/`).
  f.path = '/path/to/product'
  # [Optional] In case you want to provide information that is not present in your page set it here.
  f.variables = {
    'title': 'Product name',
    'img': 'https://flayyer.com/img/marketplace/flayyer-banner.png',
  }
  # [Optional] Custom metadata for rendering the image. ID is recommended so we provide you with better statistics.
  f.meta = {
    'id': 'jeans-123', # recommended for better stats
    'v': '12369420123', # specific handler version, by default it's a random number to circumvent platforms' cache,
    'width': 1200,
    'height': 600,
    'resolution': 0.9, # from 0.0 to 1.0
    'agent': 'whatsapp', # force dimensions for specific platform
  }
end

# Use this image in your <head/> tags (og:image & twitter:image)
puts flayyer.href
# > https://flayyer.ai/v2/website-com/_/__id=jeans-123&__v=1618281823&img=https%3A%2F%2Fflayyer.com%2Fimg%2Fmarketplace%2Fflayyer-banner.png&title=Product+name/path/to/product

# IMPORTANT: if you're using Ruby on Rails, please use `flayyer.href.html_safe` to prevent double serialization
```

For signed URLs, just provide your secret (find it in Dashboard > Project > Advanced settings) and choose a strategy (`HMAC` or `JWT`).

```ruby
flayyer = Flayyer::FlayyerAI.create do |f|
  f.project = 'website-com'
  f.path = '/path/to/product'
  f.secret = 'your-secret-key'
  f.strategy = 'JWT' # or 'HMAC'
end

url = flayyer.href
# > https://flayyer.ai/v2/website-com/jwt-eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJwYXJhbXMiOnsiX19pZCI6ImplYW5zLTEyMyJ9LCJwYXRoIjoiXC9wYXRoXC90b1wvcHJvZHVjdCJ9.X8Vs5SGEA1-3M6bH-h24jhQnbwH95V_G0f-gPhTBTzE?__v=1618283086

# IMPORTANT: if you're using Ruby on Rails, please prevent double serialization like the following:
url = flayyer.href.html_safe
```

## Flayyer.io

As you probably realized, Flayyer.ai uses the [rules defined on your dashboard](https://flayyer.com/dashboard/_/projects) to decide how to handle every image based on path patterns. It fetches and analyse your website for obtaining information and then rendering a content-rich image increasing the click-through-rate with no effort. Let's say _"FlayyerAI render images based on the content of this route"_.

Flayyer.io instead requires you to explicitly declare template and variables for the images to render, **giving you more control for customization**. Let's say _"FlayyerIO render an image using this template and these explicit variables"_.

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

# IMPORTANT: if you're using Ruby on Rails, please prevent double serialization like the following:
url = flayyer.href.html_safe
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

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Test

Run Rake tests with:

```sh
rake spec
```
