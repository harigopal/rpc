#!/usr/bin/env ruby
# encoding: utf-8

$LOAD_PATH.unshift File.expand_path("../../../lib", __FILE__)

require "rpc"

RPC.logging = true

client = RPC::Clients::EmHttpRequest.new("http://127.0.0.1:8081")

RPC::Client.new(client) do |client|
  # Get result of an existing method.
  client.server_timestamp do |result, error|
    puts "Server timestamp is #{result}"
  end

  # Get result of a non-existing method via method_missing.
  client.send(:+, 1) do |result, error|
    puts "Method missing works: #{result}"
  end

  # Synchronous error handling.
  client.buggy_method do |result, error|
    STDERR.puts "EXCEPTION CAUGHT:"
    STDERR.puts "#{error.class} #{error.message}"
  end
end
