# encoding: utf-8

# https://github.com/eventmachine/em-http-request

require "eventmachine"
require "em-http-request"

module RPC
  module Clients
    class EmHttpRequest
      def initialize(uri)
        @client = EventMachine::HttpRequest.new(uri)
      end

      def run(&block)
        EM.run do
          block.call
          EM.add_timer(0.5) { EM.stop } # FIXME: Is there any way how to stop reactor when there are no remaining events? If not, we'd need to add callback for each request which would test if there are other active requests AND if the run &block is already finished.
        end
      end

      def send(data, &callback)
        request = @client.post(body: data)
        request.callback do |response|
          callback.call(response.response)
        end
      end

      def async?
        true
      end
    end
  end
end
