#!/usr/bin/env rackup --port 8081
# encoding: utf-8

# http://groups.google.com/group/json-rpc/web/json-rpc-over-http

$LOAD_PATH.unshift File.expand_path("../../../lib", __FILE__)

require "rpc"
require "rack/request"

RPC.logging = true

class RpcRunner
  def server
    @server ||= RPC::Server.new(RemoteObject.new)
  end

  def call(env)
    request = Rack::Request.new(env)
    command = request.body.read
    binary  = self.server.execute(command)
    if binary.match(/NoMethodError/)
      response(404, binary)
    else
      response(200, binary)
    end
  end

  def response(status, body)
    headers = {
      "Content-Type" => "application/json-rpc",
      "Content-Length" => body.bytesize.to_s,
      "Accept" => "application/json-rpc"}
    [status, headers, [body]]
  end
end

class RemoteObject
  def server_timestamp
    Time.now.to_i
  end

  def buggy_method
    raise "It doesn't work!"
  end

  def method_missing(name, *args)
    "[SERVER] received method #{name} with #{args.inspect}"
  end
end

map("/") do
  run RpcRunner.new
end
