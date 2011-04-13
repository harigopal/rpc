# encoding: utf-8

# http://en.wikipedia.org/wiki/JSON-RPC

begin
  require "yajl/json_gem"
rescue LoadError
  require "json"
end

module RPC
  module Encoders
    module Json
      class Client
        def encode(method, *args)
          data = {method: method, params: args, id: self.generate_id}
          RPC.log "CLIENT ENCODE #{data.inspect}"
          JSON.generate(data)
        end

        def generate_id
          rand(1000)
        end

        def decode(binary)
          RPC.log "CLIENT DECODE #{JSON.parse(binary).inspect}"
          JSON.parse(binary)
        end
      end

      class Server
        def decode(binary)
          RPC.log "SERVER DECODE #{JSON.parse(binary).inspect}"
          JSON.parse(binary)
        end

        def execute(encoded_command, subject)
          command = self.decode(encoded_command)
          method, args = command["method"], command["params"]
          result = subject.send(method, *args)
          self.encode(result, nil, command["id"])
        rescue Exception => exception
          error = self.error(exception)
          self.encode(nil, error, command["id"])
        end

        def encode(result, error, id)
          RPC.log "SERVER ENCODE: #{{result: result, error: error, id: id}.inspect}"
          JSON.generate(result: result, error: error, id: id)
        end

        # http://json-rpc.org/wd/JSON-RPC-1-1-WD-20060807.html#ErrorObject
        # TODO: code
        def error(exception)
          message = "#{exception.class}: #{exception.message}"
          object = {class: exception.class.to_s, message: exception.message, backtrace: exception.backtrace}
          {name: "JSONRPCError", code: 000, message: message, error: object}
        end
      end
    end
  end
end
