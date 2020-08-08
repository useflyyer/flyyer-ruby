RSpec.describe Flayyer do
  it "has a version number" do
    expect(Flayyer::VERSION).not_to be nil
  end
end

RSpec.describe Flayyer::FlayyerURL do
  it "encodes url" do
    flayyer = Flayyer::FlayyerURL.create do |f|
      f.tenant = 'tenant'
      f.deck = 'deck'
      f.template = 'template'
      f.variables = {
          title: 'Hello world!'
      }
    end
    href = flayyer.href
    expect(href).to start_with("https://flayyer.host/v2/tenant/deck/template.jpeg?__v=")
    expect(href).to end_with("&title=Hello+world%21")
  end

  it "raises if missing arguments" do
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
    expect(href).to start_with("https://flayyer.host/v2/tenant/deck/template.jpeg?__v=")
  end
end

RSpec.describe Flayyer::FlayyerHash do
  it "stringifies hash of primitives" do
    hash = { a: 'hello', b: 100, c: false, d: nil, b: 999 }
    str = Flayyer::FlayyerHash.new(hash).to_query
    expect(str).to eq("a=hello&b=999&c=false&d")
  end

  it "stringifies a complex hash" do
    hash = { a: { aa: 'bar', ab: 'foo' }, b: [{ c: 'foo' }, { c: 'bar' }] }
    str = Flayyer::FlayyerHash.new(hash).to_query
    decoded = CGI.unescape(str)
    expect(decoded).to eq("a[aa]=bar&a[ab]=foo&b[0][c]=foo&b[1][c]=bar")
  end
end
