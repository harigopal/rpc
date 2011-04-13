# encoding: utf-8

require "net/http"

module RPC
  module Clients
    class NetHttp
      def initialize(host, port = 80, path = "/")
        @host, @port, @path = host, port, path
        @client = Net::HTTP.start(host, port)
      end

      def connect
        @client.start
      end

      def disconnect
        @client.finish
      end

      def send(data)
        @client.post(@path, data).body
      end

      def async?
        false
      end
    end
  end
end
