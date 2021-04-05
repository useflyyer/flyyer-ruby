require 'flayyer/version'
require 'uri'
require 'openssl'
require 'jwt'

module Flayyer
  class Error < StandardError; end

  class FlayyerAI
    attr_accessor :project, :path, :variables, :meta, :secret, :strategy

    def self.create(&block)
      self.new(&block)
    end

    def initialize(project = nil, path = nil, variables = {}, meta = {}, secret = nil, strategy = nil)
      @project = project
      @path = path || "/"
      @variables = variables
      @meta = meta
      @secret = secret
      @strategy = strategy
      yield(self) if block_given?
    end

    def path_safe
      @path.start_with?("/") ? @path : "/#{@path}"
    end

    def querystring(ignoreV = false)
      # Allow accesing the keys of @meta with symbols and strings
      # https://stackoverflow.com/a/10786575
      @meta.default_proc = proc do |h, k|
        case k
        when String then sym = k.to_sym; h[sym] if h.key?(sym)
        when Symbol then str = k.to_s; h[str] if h.key?(str)
        end
      end

      if !ignoreV then
        defaults = {
          __v: @meta[:v].nil? ? Time.now.to_i : @meta[:v], # This forces crawlers to refresh the image
          __id: @meta[:id] || nil,
          _w: @meta[:width] || nil,
          _h: @meta[:height] || nil,
          _res: @meta[:resolution] || nil,
          _ua: @meta[:agent] || nil
        }
        result = FlayyerHash.new(@variables.nil? ? defaults : defaults.merge(@variables))
        result.to_query.split("&").sort().join("&")
      else
        defaults = {
          __id: @meta[:id] || nil,
          _w: @meta[:width] || nil,
          _h: @meta[:height] || nil,
          _res: @meta[:resolution] || nil,
          _ua: @meta[:agent] || nil
        }
        result = FlayyerHash.new(@variables.nil? ? defaults : defaults.merge(@variables))
        result.to_query.split("&").sort().join("&")
      end
    end

    def sign
      return '_' if @strategy.nil? and @secret.nil?
      raise Error.new('Got `strategy` but missing `secret`. You can find it in your project in Advanced settings.') if @secret.nil?
      raise Error.new('Got `secret` but missing `strategy`.  Valid options are `HMAC` or `JWT`.') if @strategy.nil?
      key = @secret
      data = "#{@project}#{self.path_safe}#{self.querystring(true)}"
      if strategy.downcase == "hmac" then
        mac = OpenSSL::HMAC.hexdigest('SHA256', key, data)
        mac[0..15]
      elsif strategy.downcase == "jwt"
        payload = @variables.merge(@meta)
        JWT.encode(payload, key, 'HS256')
      else
        raise Error.new('Invalid `strategy`. Valid options are `HMAC` or `JWT`.')
      end
    end

    # Create a https://flayyer.com string.
    # If you are on Ruby on Rails please use .html_safe when rendering this string into the HTML
    def href
      raise Error.new('Missing "project" property') if @project.nil?

      signature = self.sign
      params = self.querystring
      if strategy.nil? || strategy != "JWT" then
        "https://flayyer.ai/v2/#{@project}/#{signature}/#{params}#{self.path_safe}"
      else
        "https://flayyer.ai/v2/#{@project}/jwt-#{signature}?__v=#{Time.now.to_i}"
      end
    end
  end

  class FlayyerURL
    attr_accessor :version, :tenant, :deck, :template, :extension, :variables, :meta

    def self.create(&block)
      self.new(&block)
    end

    def initialize(tenant = nil, deck = nil, template = nil, version = nil, extension = 'jpeg', variables = {}, meta = {})
      @tenant = tenant
      @deck = deck
      @template = template
      @version = version
      @extension = extension
      @variables = variables
      @meta = meta
      yield(self) if block_given?
    end

    def querystring
      # Allow accesing the keys of @meta with symbols and strings
      # https://stackoverflow.com/a/10786575
      @meta.default_proc = proc do |h, k|
        case k
          when String then sym = k.to_sym; h[sym] if h.key?(sym)
          when Symbol then str = k.to_s; h[str] if h.key?(str)
        end
      end

      defaults = {
        __v: @meta[:v].nil? ? Time.now.to_i : @meta[:v], # This forces crawlers to refresh the image
        __id: @meta[:id] || nil,
        _w: @meta[:width] || nil,
        _h: @meta[:height] || nil,
        _res: @meta[:resolution] || nil,
        _ua: @meta[:agent] || nil
      }
      result = FlayyerHash.new(@variables.nil? ? defaults : defaults.merge(@variables))
      result.to_query
    end

    # Create a https://flayyer.com string.
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
        elsif v.nil?
          # skip null values
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
