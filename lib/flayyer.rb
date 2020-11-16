require 'flayyer/version'
require 'uri'

module Flayyer
  class Error < StandardError; end

  class FlayyerURL
    attr_accessor :version, :tenant, :deck, :template, :extension, :variables

    def self.create(&block)
      self.new(&block)
    end

    def initialize(tenant = nil, deck = nil, template = nil, version = nil, extension = 'jpeg', variables = {})
      @tenant = tenant
      @deck = deck
      @template = template
      @version = version
      @extension = extension
      @variables = variables
      yield(self) if block_given?
    end

    def querystring
      defaults = {
        __v: Time.now.to_i, # This forces crawlers to refresh the image
      }
      result = FlayyerHash.new(@variables.nil? ? defaults : defaults.merge(@variables))
      result.to_query
    end

    # Create a https://FLAYYER.com string.
    # If you are on Ruby on Rails please use .html_safe when rendering this string into the HTML
    def href
      raise Error.new('Missing "tenant" property') if @tenant.nil?
      raise Error.new('Missing "deck" property') if @deck.nil?
      raise Error.new('Missing "template" property') if @template.nil?

      if @version.nil?
        "https://flayyer.io/v2/#{@tenant}/#{@deck}/#{@template}.#{@extension}?#{self.querystring}"
      else
        "https://flayyer.io/v2/#{@tenant}/#{@deck}/#{@template}.#{@version}.#{@extension}?#{self.querystring}"
      end
    end
  end

  # A compatible qs stringify/parse (https://github.com/ljharb/qs)
  class FlayyerHash
    @hash = {}
    def initialize(hash)
      @hash = hash
    end

    def to_query_hash(key)
      @hash.reduce({}) do |h, (k, v)|
        new_key = key.nil? ? k : "#{key}[#{k}]"
        v = Hash[v.each_with_index.to_a.map(&:reverse)] if v.is_a?(Array)
        if v.is_a?(Hash)
          h.merge!(FlayyerHash.new(v).to_query_hash(new_key))
        else
          h[new_key] = v
        end
        h
      end
    end

    def to_query(key = nil)
      URI.encode_www_form(self.to_query_hash(key))
    end
  end
end
