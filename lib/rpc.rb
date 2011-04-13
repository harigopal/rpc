# encoding: utf-8

module RPC
  module Clients
    autoload :NetHttp, "rpc/clients/net-http"
  end

  module Encoders
    autoload :Json, "rpc/encoders/json"
  end

  def self.logging
    @logging ||= $DEBUG
  end

  def self.logging=(boolean)
    @logging = boolean
  end

  def self.log(message)
    if self.logging
      STDERR.puts(message)
    end
  end

  def self.full_const_get(const_name)
    parts = const_name.sub(/^::/, "").split("::")
    parts.reduce(Object) do |constant, part|
      constant.const_get(part)
    end
  end

  class Server
    def initialize(subject, encoder = RPC::Encoders::Json::Server.new)
      @subject, @encoder = subject, encoder
    end

    def execute(encoded_command)
      @encoder.execute(encoded_command, @subject)
    end
  end

  module ExceptionsMixin
    attr_accessor :server_backtrace

    # NOTE: We can't use super to get the client backtrace,
    # because backtrace is generated only if there is none
    # yet and because we are redefining the backtrace method,
    # there always will be some backtrace.
    def backtrace
      @backtrace ||= begin
        caller(3) + ["... server ..."] + self.server_backtrace
      end
    end
  end

  class Client < BasicObject
    def self.setup(host, port, client_class = Clients::NetHttp, encoder = Encoders::Json::Client.new)
      client = client_class.new(host, port)
      self.new(client, encoder)
    end

    def initialize(client, encoder)
      @client, @encoder, @callbacks = client, encoder, ::Hash.new
    end

    # 1) Sync: it'll return the value.
    # 2) Async: you have to add #subscribe
    def method_missing(method, *args, &callback)
      binary = @encoder.encode(method, *args)

      if @client.async?
        @callbacks[id] = callback if callback
        @client.send(binary)
      else
        ::Kernel.raise("You can't specify callback for a synchronous client.") if callback

        encoded_result = @client.send(binary)
        result = @encoder.decode(encoded_result)

        if error = result["error"]
          exception = self.get_exception(error)
          ::Kernel.raise(exception)
        else
          result["result"]
        end
      end
    end

    def get_exception(error)
      return unless error
      exception = error["error"]
      resolved_class = ::RPC.full_const_get(exception["class"])
      klass = resolved_class || ::RuntimeError
      message = resolved_class ? exception["message"] : error["message"]
      instance = klass.new(message)
      instance.extend(::RPC::ExceptionsMixin)
      instance.server_backtrace = exception["backtrace"]
      instance
    end

    def subscribe(*args, &block)
      ::Kernel.raise("Client is synchronous") unless @client.async?
      @client.subscribe(self, *args, &block)
    end

    def receive(encoded_result)
      result = @encoder.decode(encoded_result)
      if callback = @callbacks[result["id"]]
        @callbacks.delete(result["id"])
        callback.call(result["result"], get_exception(result["error"]))
      end
    end
  end
end
