require 'flyyer/version'
require 'uri'
require 'openssl'
require 'jwt'

module Flyyer
  class Error < StandardError; end

  class Flyyer
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

    def params_hash(ignoreV)
      defaults = {
        __v: @meta[:v] || Time.now.to_i, # This forces crawlers to refresh the image
        __id: @meta[:id] || nil,
        _w: @meta[:width] || nil,
        _h: @meta[:height] || nil,
        _res: @meta[:resolution] || nil,
        _ua: @meta[:agent] || nil
      }
      defaults.delete(:__v) if ignoreV
      @variables.nil? ? defaults : defaults.merge(@variables)
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

      defaults = self.params_hash(ignoreV)
      result = FlyyerHash.new(defaults)
      result.to_query.split("&").sort().join("&")
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
        payload = { "params": self.params_hash(true).compact, "path": self.path_safe}
        JWT.encode(payload, key, 'HS256')
      else
        raise Error.new('Invalid `strategy`. Valid options are `HMAC` or `JWT`.')
      end
    end

    # Create a https://FLYYER.io string.
    # If you are on Ruby on Rails please use .html_safe when rendering this string into the HTML
    def href
      raise Error.new('Missing "project" property') if @project.nil?

      signature = self.sign
      params = self.querystring
      if strategy.nil? || strategy != "JWT" then
        "https://cdn.flyyer.io/v2/#{@project}/#{signature}/#{params}#{self.path_safe}"
      else
        "https://cdn.flyyer.io/v2/#{@project}/jwt-#{signature}?__v=#{@meta[:v] || Time.now.to_i}"
      end
    end
  end

  class FlyyerRender
    attr_accessor :version, :tenant, :deck, :template, :extension, :variables, :meta, :secret, :strategy

    def self.create(&block)
      self.new(&block)
    end

    def initialize(tenant = nil, deck = nil, template = nil, version = nil, extension = nil, variables = {}, meta = {}, secret = nil, strategy = nil)
      @tenant = tenant
      @deck = deck
      @template = template
      @version = version
      @extension = extension
      @variables = variables
      @meta = meta
      @secret = secret
      @strategy = strategy
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

      default_v = {
        __v: @meta[:v].nil? ? Time.now.to_i : @meta[:v], # This forces crawlers to refresh the image
      }
      defaults_without_v = {
        __id: @meta[:id] || nil,
        _w: @meta[:width] || nil,
        _h: @meta[:height] || nil,
        _res: @meta[:resolution] || nil,
        _ua: @meta[:agent] || nil,
      }
      if @strategy && @secret
        key = @secret
        if @strategy.downcase == "hmac"
          hashed_without_v = FlyyerHash.new(defaults_without_v.merge(@variables || {}))
          data = [@deck, @template, @version || "", @extension || "", hashed_without_v.to_query].join("#")
          __hmac = OpenSSL::HMAC.hexdigest('SHA256', key, data)[0..15]
          return FlyyerHash.new([default_v, defaults_without_v, @variables || {}, {__hmac: __hmac}].inject(&:merge)).to_query
        end
        if @strategy.downcase == "jwt"
          payload = [
            { deck: @deck, template: @template, version: @version, ext: @extension },
            defaults_without_v,
            variables || {},
          ].inject(&:merge)
          __jwt = JWT.encode(payload, key, 'HS256')
          __v = @meta[:v].nil? ? Time.now.to_i : @meta[:v]
          return FlyyerHash.new({ __jwt: __jwt, __v: __v }).to_query
        end
      else
        return FlyyerHash.new([default_v, defaults_without_v, @variables || {}].inject(&:merge)).to_query
      end
    end

    # Create a https://flyyer.io string.
    # If you are on Ruby on Rails please use .html_safe when rendering this string into the HTML
    def href
      raise Error.new('Missing "tenant" property') if @tenant.nil?
      raise Error.new('Missing "deck" property') if @deck.nil?
      raise Error.new('Missing "template" property') if @template.nil?
      raise Error.new('Got `secret` but missing `strategy`.  Valid options are `HMAC` or `JWT`.') if @secret && @strategy.nil?
      raise Error.new('Got `strategy` but missing `secret`. You can find it in your project in Advanced settings.') if @strategy && @secret.nil?
      raise Error.new('Invalid signing `strategy`. Valid options are `HMAC` or `JWT`.') if @strategy && @strategy.downcase != "jwt" && @strategy.downcase != "hmac"

      base_href = "https://cdn.flyyer.io/render/v2/#{@tenant}"

      if @strategy and @strategy.downcase == "jwt"
        return "#{base_href}?#{self.querystring}"
      end

      final_href = "#{base_href}/#{@deck}/#{@template}"
      final_href << ".#{@version}" if @version
      final_href << ".#{@extension}" if @extension
      final_href << "?#{self.querystring}"
    end
  end

  # A compatible qs stringify/parse (https://github.com/ljharb/qs)
  class FlyyerHash
    @hash = {}
    def initialize(hash)
      @hash = hash
    end

    def to_query_hash(key)
      @hash.reduce({}) do |h, (k, v)|
        new_key = key.nil? ? k : "#{key}[#{k}]"
        v = Hash[v.each_with_index.to_a.map(&:reverse)] if v.is_a?(Array)
        if v.is_a?(Hash)
          h.merge!(FlyyerHash.new(v).to_query_hash(new_key))
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
