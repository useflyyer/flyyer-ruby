RSpec.describe Flayyer do
  it 'has a version number' do
    expect(Flayyer::VERSION).not_to be nil
  end
end

RSpec.describe Flayyer::FlayyerURL do
  it 'encodes url' do
    flayyer = Flayyer::FlayyerURL.create do |f|
      f.tenant = 'tenant'
      f.deck = 'deck'
      f.template = 'template'
      f.variables = {
        title: 'Hello world!',
        description: nil,
        'img' => ''
      }
      f.meta = {
        id: 'dev forgot to slugify',
        width: '100',
        height: 200
      }
      f.meta['resolution'] = 1.0 # test with string key
    end
    href = flayyer.href
    expect(href).to start_with('https://flayyer.io/v2/tenant/deck/template.jpeg?__v=')
    expect(href).to include('&title=Hello+world%21')
    expect(href).to include('&img=')
    expect(href).to include('&__id=dev+forgot+to+slugify')
    expect(href).to include('&_w=100')
    expect(href).to include('&_h=200')
    expect(href).to include('&_res=1.0')
    expect(href).not_to include('&description')
  end

  it 'raises if missing arguments' do
    flayyer = Flayyer::FlayyerURL.create do |f|
      f.tenant = 'tenant'
    end
    expect(flayyer.tenant).to eq('tenant')
    expect(flayyer.deck).to eq(nil)
    expect(flayyer.template).to eq(nil)
    expect(flayyer.version).to eq(nil)
    expect(flayyer.extension).to eq('jpeg')
    expect { flayyer.href }.to raise_error(Flayyer::Error)

    flayyer = Flayyer::FlayyerURL.create do |f|
      f.tenant = 'tenant'
      f.deck = 'deck'
    end
    expect(flayyer.tenant).to eq('tenant')
    expect(flayyer.deck).to eq('deck')
    expect(flayyer.template).to eq(nil)
    expect(flayyer.version).to eq(nil)
    expect(flayyer.extension).to eq('jpeg')
    expect { flayyer.href }.to raise_error(Flayyer::Error)

    flayyer = Flayyer::FlayyerURL.create do |f|
      f.tenant = 'tenant'
      f.deck = 'deck'
      f.template = 'template'
    end
    expect(flayyer.tenant).to eq('tenant')
    expect(flayyer.deck).to eq('deck')
    expect(flayyer.template).to eq('template')
    expect(flayyer.version).to eq(nil)
    expect(flayyer.extension).to eq('jpeg')
    href = flayyer.href
    expect(href).to start_with('https://flayyer.io/v2/tenant/deck/template.jpeg?__v=')
  end
end

RSpec.describe Flayyer::FlayyerAI do
  it 'encodes url happy path' do
    flayyer = Flayyer::FlayyerAI.create do |f|
      f.project = 'project'
      f.path = '/path/to/product'
      f.variables = {
        title: 'Hello world!',
        description: nil,
        'img' => ''
      }
      f.meta = {
        id: 'dev forgot to slugify',
        width: '100',
        height: 200,
        v: ''
      }
      f.meta['resolution'] = 1.0 # test with string key
    end
    href = flayyer.href
    expect(href).to eq('https://flayyer.ai/v2/project/_/__id=dev+forgot+to+slugify&__v=&_h=200&_res=1.0&_w=100&img=&title=Hello+world%21/path/to/product')
  end
end

RSpec.describe Flayyer::FlayyerAI do
  it 'encodes url with default values' do
    flayyer = Flayyer::FlayyerAI.create do |f|
      f.project = 'project'
    end
    href = flayyer.href
    expect(href).to match(/https:\/\/flayyer.ai\/v2\/project\/_\/__v=\d+\//)
  end
end

RSpec.describe Flayyer::FlayyerAI do
  it 'encodes url with path missing / at start' do
    flayyer = Flayyer::FlayyerAI.create do |f|
      f.project = 'project'
      f.path = 'path/to/product'
    end
    href = flayyer.href
    expect(href).to match(/https:\/\/flayyer.ai\/v2\/project\/_\/__v=\d+\/path\/to\/product/)
  end
end

RSpec.describe Flayyer::FlayyerAI do
  it 'encodes url with query params' do
    flayyer = Flayyer::FlayyerAI.create do |f|
      f.project = 'project'
      f.path = '/path/to/collection?sort=price'
    end
    href = flayyer.href
    expect(href).to match(/https:\/\/flayyer.ai\/v2\/project\/_\/__v=\d+\/path\/to\/collection\/?\?sort=price/)
  end
end

RSpec.describe Flayyer::FlayyerAI do
  it 'encodes url with hmac signature' do
    flayyer = Flayyer::FlayyerAI.create do |f|
      f.project = 'project'
      f.path = '/collections/col'
      f.secret = 'sg1j0HVy9bsMihJqa8Qwu8ZYgCYHG0tx'
      f.strategy = "HMAC"
      f.meta = {
        id: 'dev forgot to slugify',
        width: '100',
        height: 200,
      }
    end
    href = flayyer.href
    expect(href).to match(/https:\/\/flayyer.ai\/v2\/project\/e8771c307e66652f\/__id=dev\+forgot\+to\+slugify&__v=\d+&_h=200&_w=100\/collections\/col\/?/)
  end
end

RSpec.describe Flayyer::FlayyerAI do
  it 'encodes url with jwt' do
    flayyer = Flayyer::FlayyerAI.create do |f|
      f.project = 'project'
      f.path = '/collections/col'
      f.secret = 'sg1j0HVy9bsMihJqa8Qwu8ZYgCYHG0tx'
      f.strategy = 'JWT'
      f.meta = {
        id: 'dev forgot to slugify',
        width: '100',
        height: 200,
      }
    end
    href = flayyer.href
    expect(href).to match(/https:\/\/flayyer.ai\/v2\/project\/jwt-eyJhbGciOiJIUzI1NiJ9.eyJpZCI6ImRldiBmb3Jnb3QgdG8gc2x1Z2lmeSIsIndpZHRoIjoiMTAwIiwiaGVpZ2h0IjoyMDB9.0KpbuqbwJyNVNqPOJO_LzvqOXCQK51_WbGEm3pFyY9s\/?\?__v=\d+/)
  end
end

RSpec.describe Flayyer::FlayyerAI do
  it 'encodes url with jwt with path missing / at start' do
    flayyer = Flayyer::FlayyerAI.create do |f|
      f.project = 'project'
      f.path = 'collections/col'
      f.secret = 'sg1j0HVy9bsMihJqa8Qwu8ZYgCYHG0tx'
      f.strategy = 'JWT'
      f.meta = {
        id: 'dev forgot to slugify',
        width: '100',
        height: 200,
      }
    end
    href = flayyer.href
    expect(href).to match(/https:\/\/flayyer.ai\/v2\/project\/jwt-eyJhbGciOiJIUzI1NiJ9.eyJpZCI6ImRldiBmb3Jnb3QgdG8gc2x1Z2lmeSIsIndpZHRoIjoiMTAwIiwiaGVpZ2h0IjoyMDB9.0KpbuqbwJyNVNqPOJO_LzvqOXCQK51_WbGEm3pFyY9s\/?\?__v=\d+/)
  end
end

RSpec.describe Flayyer::FlayyerHash do
  it 'stringifies hash of primitives' do
    hash = { a: 'hello', b: 100, c: false, d: nil, b: 999 }
    str = Flayyer::FlayyerHash.new(hash).to_query
    expect(str).to eq('a=hello&b=999&c=false')
  end

  it 'stringifies a complex hash' do
    hash = { a: { aa: 'bar', ab: 'foo' }, b: [{ c: 'foo' }, { c: 'bar' }] }
    str = Flayyer::FlayyerHash.new(hash).to_query
    decoded = CGI.unescape(str)
    expect(decoded).to eq('a[aa]=bar&a[ab]=foo&b[0][c]=foo&b[1][c]=bar')
  end
end
