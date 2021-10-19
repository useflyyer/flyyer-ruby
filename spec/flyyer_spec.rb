require 'jwt'

RSpec.describe Flyyer do
  it 'has a version number' do
    expect(Flyyer::VERSION).not_to be nil
  end
end

RSpec.describe Flyyer::FlyyerHash do
  it 'stringifies hash of primitives' do
    hash = { a: 'hello', b: 100, c: false, d: nil, b: 999 }
    str = Flyyer::FlyyerHash.new(hash).to_query
    expect(str).to eq('a=hello&b=999&c=false')
  end

  it 'stringifies a complex hash' do
    hash = { a: { aa: 'bar', ab: 'foo' }, b: [{ c: 'foo' }, { c: 'bar' }] }
    str = Flyyer::FlyyerHash.new(hash).to_query
    decoded = CGI.unescape(str)
    expect(decoded).to eq('a[aa]=bar&a[ab]=foo&b[0][c]=foo&b[1][c]=bar')
  end
end

RSpec.describe Flyyer::FlyyerRender do
  it 'encodes url' do
    flyyer = Flyyer::FlyyerRender.create do |f|
      f.tenant = 'tenant'
      f.deck = 'deck'
      f.template = 'template'
      f.variables = {
        title: 'Hello world!',
        description: nil,
        'img' => ''
      }
      f.extension = "jpeg"
      f.meta = {
        id: 'dev forgot to slugify',
        width: '100',
        height: 200
      }
      f.meta['resolution'] = 1.0 # test with string key
    end
    href = flyyer.href
    expect(href).to start_with('https://cdn.flyyer.io/render/v2/tenant/deck/template.jpeg?')
    expect(href).to include('__v=')
    expect(href).to include('title=Hello+world%21')
    expect(href).to include('img=')
    expect(href).to include('__id=dev+forgot+to+slugify')
    expect(href).to include('_w=100')
    expect(href).to include('_h=200')
    expect(href).to include('_res=1.0')
    expect(href).not_to include('description=')
  end

  it 'raises if missing arguments' do
    flyyer = Flyyer::FlyyerRender.create do |f|
      f.tenant = 'tenant'
    end
    expect(flyyer.tenant).to eq('tenant')
    expect(flyyer.deck).to eq(nil)
    expect(flyyer.template).to eq(nil)
    expect(flyyer.version).to eq(nil)
    expect(flyyer.extension).to eq(nil)
    expect { flyyer.href }.to raise_error(Flyyer::Error)

    flyyer = Flyyer::FlyyerRender.create do |f|
      f.tenant = 'tenant'
      f.deck = 'deck'
    end
    expect(flyyer.tenant).to eq('tenant')
    expect(flyyer.deck).to eq('deck')
    expect(flyyer.template).to eq(nil)
    expect(flyyer.version).to eq(nil)
    expect(flyyer.extension).to eq(nil)
    expect { flyyer.href }.to raise_error(Flyyer::Error)

    flyyer = Flyyer::FlyyerRender.create do |f|
      f.tenant = 'tenant'
      f.deck = 'deck'
      f.template = 'template'
    end
    expect(flyyer.tenant).to eq('tenant')
    expect(flyyer.deck).to eq('deck')
    expect(flyyer.template).to eq('template')
    expect(flyyer.version).to eq(nil)
    expect(flyyer.extension).to eq(nil)
    href = flyyer.href
    expect(href).to start_with('https://cdn.flyyer.io/render/v2/tenant/deck/template?__v=')

    flyyer = Flyyer::FlyyerRender.create do |f|
      f.tenant = 'tenant'
      f.deck = 'deck'
      f.template = 'template'
      f.strategy = "hmac"
      f.secret = nil
    end
    expect(flyyer.tenant).to eq('tenant')
    expect(flyyer.deck).to eq('deck')
    expect(flyyer.template).to eq('template')
    expect(flyyer.version).to eq(nil)
    expect(flyyer.extension).to eq(nil)
    expect { flyyer.href }.to raise_error(Flyyer::Error)
  end

  it 'encodes url with hmac signature' do
    flyyer = Flyyer::FlyyerRender.create do |f|
      f.tenant = 'tenant'
      f.deck = 'deck'
      f.template = 'template'
      f.extension = 'jpeg'
      f.secret = 'sg1j0HVy9bsMihJqa8Qwu8ZYgCYHG0tx'
      f.strategy = 'HMAC'
      f.variables = {
        title: 'Hello world!'
      }
    end
    href = flyyer.href
    expect(href).to match(%r{https:\/\/cdn.flyyer.io\/render\/v2\/tenant\/deck\/template.jpeg\?__v=\d+&title=Hello\+world%21&__hmac=6b631ae8c4ca2977})
  end

  it 'encodes url with jwt with default values' do
    key = 'sg1j0HVy9bsMihJqa8Qwu8ZYgCYHG0tx'
    flyyer = Flyyer::FlyyerRender.create do |f|
      f.tenant = 'tenant'
      f.deck = 'deck'
      f.template = 'template'
      f.secret = key
      f.strategy = "JWT"
      f.version = 4
      f.variables = {}
      f.meta = {}
    end
    href = flyyer.href
    raw = href.scan(/jwt=.*/).first
    token = raw.slice(4..(raw.index('&__v=') || raw.length) - 1)
    decoded = JWT.decode(token, key, true, { algorithm: 'HS256' })
    payload = decoded.first
    expect(payload).to eq({"i"=>nil, "h"=>nil, "r"=>nil, "u"=>nil, "w"=>nil, "d"=>"deck", "e"=>nil, "t"=>"template", "v"=>4, "var"=>{}})
    expect(href).to match(%r{https:\/\/cdn.flyyer.io\/render\/v2\/tenant\?__jwt=.*?\&__v=\d+})
  end

  it 'encodes url with jwt with meta and variables' do
    key = 'sg1j0HVy9bsMihJqa8Qwu8ZYgCYHG0tx'
    flyyer = Flyyer::FlyyerRender.create do |f|
      f.tenant = 'tenant'
      f.deck = 'deck'
      f.template = 'template'
      f.secret = key
      f.strategy = "JWT"
      f.version = 4
      f.meta = {
        id: 'dev forgot to slugify',
        width: '100',
        height: 200
      }
      f.variables = {
        title: 'Hello world!'
      }
    end
    href = flyyer.href
    raw = href.scan(/jwt=.*/).first
    token = raw.slice(4..(raw.index('&__v=') || raw.length) - 1)
    decoded = JWT.decode(token, key, true, { algorithm: 'HS256' })
    payload = decoded.first
    expect(payload).to eq({"i"=>"dev forgot to slugify", "h"=>200, "r"=>nil, "u"=>nil, "w"=>"100", "d"=>"deck", "e"=>nil, "t"=>"template", "v"=>4, "var"=>{"title"=>"Hello world!"}})
    expect(href).to match(%r{https:\/\/cdn.flyyer.io\/render\/v2\/tenant\?__jwt=.*?\&__v=\d+})
  end
end

RSpec.describe Flyyer::Flyyer do
  it 'encodes url happy path' do
    flyyer = Flyyer::Flyyer.create do |f|
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
    href = flyyer.href
    expect(href).to eq('https://cdn.flyyer.io/v2/project/_/__id=dev+forgot+to+slugify&__v=&_h=200&_res=1.0&_w=100&img=&title=Hello+world%21/path/to/product')
  end

  it 'encodes url with default values' do
    flyyer = Flyyer::Flyyer.create do |f|
      f.project = 'project'
    end
    href = flyyer.href
    expect(href).to match(%r{https://cdn.flyyer.io/v2/project/_/__v=\d+})
  end

  it 'encodes url with path missing / at start' do
    flyyer = Flyyer::Flyyer.create do |f|
      f.project = 'project'
      f.path = 'path/to/product'
    end
    href = flyyer.href
    expect(href).to match(%r{https://cdn.flyyer.io/v2/project/_/__v=\d+/path/to/product})
  end

  it 'encodes url with query params' do
    flyyer = Flyyer::Flyyer.create do |f|
      f.project = 'project'
      f.path = '/path/to/collection?sort=price'
    end
    href = flyyer.href
    expect(href).to match(%r{https://cdn.flyyer.io/v2/project/_/__v=\d+/path/to/collection\?sort=price})
  end

  it 'sets `default` image as `_def` param' do
    flyyer0 = Flyyer::Flyyer.create do |f|
      f.project = 'project'
      f.path = 'path'
      f.default = '/static/product/1.png'
    end
    href0 = flyyer0.href
    expect(href0).to match(%r{https://cdn.flyyer.io/v2/project/_/__v=(\d+)&_def=%2Fstatic%2Fproduct%2F1.png/path})
    flyyer1 = Flyyer::Flyyer.create do |f|
      f.project = 'project'
      f.path = 'path'
      f.default = 'https://www.flyyer.io/logo.png'
    end
    href1 = flyyer1.href
    expect(href1).to match(%r{https://cdn.flyyer.io/v2/project/_/__v=(\d+)&_def=https%3A%2F%2Fwww.flyyer.io%2Flogo.png/path})
  end

  it 'encodes url with hmac signature' do
    flyyer = Flyyer::Flyyer.create do |f|
      f.project = 'project'
      f.path = '/collections/col'
      f.secret = 'sg1j0HVy9bsMihJqa8Qwu8ZYgCYHG0tx'
      f.strategy = 'HMAC'
      f.meta = {
        id: 'dev forgot to slugify',
        width: '100',
        height: 200
      }
      f.variables = {
        title: 'Hello world!'
      }
    end
    href = flyyer.href
    expect(href).to match(%r{https://cdn.flyyer.io/v2/project/361b2a456daf8415/__id=dev\+forgot\+to\+slugify&__v=\d+&_h=200&_w=100&title=Hello\+world%21/collections/col})
  end

  it 'encodes url with jwt with default values' do
    key = 'sg1j0HVy9bsMihJqa8Qwu8ZYgCYHG0tx'
    flyyer = Flyyer::Flyyer.create do |f|
      f.project = 'project'
      f.secret = key
      f.strategy = 'JWT'
      f.variables = {}
      f.meta = {}
    end
    href = flyyer.href

    token = href.scan(/(jwt-)(.*)(\?)/).last[1]
    decoded = JWT.decode(token, key, true, { algorithm: 'HS256' })
    payload = decoded.first
    expect(payload['params']).to eq({ "var" => {}})
    expect(payload['path']).to eq('/')
  end

  it 'encodes url with jwt with meta' do
    key = 'sg1j0HVy9bsMihJqa8Qwu8ZYgCYHG0tx'
    flyyer = Flyyer::Flyyer.create do |f|
      f.project = 'project'
      f.path = '/collections/col'
      f.secret = key
      f.strategy = 'JWT'
      f.variables = {}
      f.meta = {
        id: 'dev forgot to slugify',
        width: '100',
        height: 200
      }
    end
    href = flyyer.href
    token = href.scan(/(jwt-)(.*)(\?)/).last[1]
    decoded = JWT.decode(token, key, true, { algorithm: 'HS256' })
    payload = decoded.first
    expect(payload['params']['w']).to eq('100')
    expect(payload['params']['h']).to eq(200)
    expect(payload == { "params": flyyer.params_hash(true).compact, "path": '/collections/col' })
  end

  it 'encodes url with jwt with path missing / at start' do
    key = 'sg1j0HVy9bsMihJqa8Qwu8ZYgCYHG0tx'
    flyyer = Flyyer::Flyyer.create do |f|
      f.project = 'project'
      f.path = 'collections/col'
      f.secret = key
      f.strategy = 'JWT'
      f.meta = {
        id: 'dev forgot to slugify',
        width: '100',
        height: 200
      }
      f.variables = {
        title: 'Hello world!'
      }
    end
    href = flyyer.href
    token = href.scan(/(jwt-)(.*)(\?)/).last[1]
    decoded = JWT.decode(token, key, true, { algorithm: 'HS256' })
    payload = decoded.first
    expect(payload['params']['i']).to eq('dev forgot to slugify')
    expect(payload == { "params": flyyer.params_hash(true).compact, "path": '/collections/col' })
  end

  it 'encodes url with jwt with meta and default relative image' do
    key = 'sg1j0HVy9bsMihJqa8Qwu8ZYgCYHG0tx'
    flyyer = Flyyer::Flyyer.create do |f|
      f.project = 'project'
      f.path = '/collections/col'
      f.secret = key
      f.strategy = 'JWT'
      f.default = "/static/logo.png"
      f.variables = {}
      f.meta = {
        id: 'dev forgot to slugify',
        width: '100',
        height: 200
      }
    end
    href = flyyer.href
    token = href.scan(/(jwt-)(.*)(\?)/).last[1]
    decoded = JWT.decode(token, key, true, { algorithm: 'HS256' })
    payload = decoded.first
    expect(payload['params']['w']).to eq('100')
    expect(payload['params']['h']).to eq(200)
    expect(payload['params']['def']).to eq("/static/logo.png")
    expect(payload == { "params": flyyer.params_hash(true).compact, "path": '/collections/col' })
  end

  it 'encodes url with jwt with meta and default absolute image' do
    key = 'sg1j0HVy9bsMihJqa8Qwu8ZYgCYHG0tx'
    flyyer = Flyyer::Flyyer.create do |f|
      f.project = 'project'
      f.path = '/collections/col'
      f.secret = key
      f.strategy = 'JWT'
      f.default = "https://flyyer.io/static/logo.png"
      f.variables = {}
      f.meta = {
        id: 'dev forgot to slugify',
        width: '100',
        height: 200
      }
    end
    href = flyyer.href
    token = href.scan(/(jwt-)(.*)(\?)/).last[1]
    decoded = JWT.decode(token, key, true, { algorithm: 'HS256' })
    payload = decoded.first
    expect(payload['params']['w']).to eq('100')
    expect(payload['params']['h']).to eq(200)
    expect(payload['params']['def']).to eq("https://flyyer.io/static/logo.png")
    expect(payload == { "params": flyyer.params_hash(true).compact, "path": '/collections/col' })
  end

  it 'raises when jwt has incorrect key' do
    key1 = 'sg1j0HVy9bsMihJqa8Qwu8ZYgCYHG0tx'
    key2 = 'sg1j0HVy9bsMihJqa8Qwu8ZYgCYHG0ty'
    flyyer = Flyyer::Flyyer.create do |f|
      f.project = 'project'
      f.path = '/collections/col'
      f.secret = key1
      f.strategy = 'JWT'
    end
    href = flyyer.href
    token = href.scan(/(jwt-)(.*)(\?)/).last[1]
    JWT.decode(token, key1, true, { algorithm: 'HS256' })
    expect { JWT.decode(token, key2, true, { algorithm: 'HS256' }) }.to raise_error(JWT::VerificationError)
  end

  it 'encodes url with jwt with meta, default image & variables' do
    key = 'sg1j0HVy9bsMihJqa8Qwu8ZYgCYHG0tx'
    flyyer = Flyyer::Flyyer.create do |f|
      f.project = 'project'
      f.path = '/collections/col'
      f.secret = key
      f.strategy = 'JWT'
      f.default = "https://flyyer.io/static/logo.png"
      f.variables = {
        title: 'Hello world!',
        description: 'First variable',
      }
      f.meta = {
        id: 'dev forgot to slugify',
        width: '100',
        height: 200,
      }
    end
    href = flyyer.href
    token = href.scan(/(jwt-)(.*)(\?)/).last[1]
    decoded = JWT.decode(token, key, true, { algorithm: 'HS256' })
    payload = decoded.first
    expect(payload['params']['var']['title']).to eq('Hello world!')
    expect(payload['params']['var']['description']).to eq('First variable')
    expect(payload['params']['w']).to eq('100')
    expect(payload['params']['h']).to eq(200)
    expect(payload['params']['def']).to eq("https://flyyer.io/static/logo.png")
    expect(payload == { "params": flyyer.params_hash(true).compact, "path": '/collections/col' })
  end
end
