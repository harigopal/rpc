# encoding: utf-8

require "uri"

module Net
  autoload :HTTP,  "net/http"
  autoload :HTTPS, "net/https"
end

module RPC
  module Clients
    class NetHttp
      def initialize(uri)
        @uri = URI.parse(uri)
        klass = Net.const_get(@uri.scheme.upcase)
        @client = klass.new(@uri.host, @uri.port)
      end

      def connect
        @client.start
      end

      def disconnect
        @client.finish
      end

      def run(&block)
        self.connect
        block.call
        self.disconnect
      end

      def send(data)
        path = @uri.path.empty? ? "/" : @uri.path
        @client.post(path, data).body
      end

      def async?
        false
      end
    end
  end
end
