#!/usr/bin/env ruby
# encoding: utf-8

$LOAD_PATH.unshift File.expand_path("../../../lib", __FILE__)

require "rpc"

RPC.logging = true

client = RPC::Client.setup("http://127.0.0.1:8081")

# Get result of an existing method.
puts "Server timestamp is #{client.server_timestamp}"

# Get result of a non-existing method via method_missing.
puts "Method missing works: #{client + 1}"

# Synchronous error handling.
begin
  client.buggy_method
rescue Exception => exception
  STDERR.puts "EXCEPTION CAUGHT:"
  raise exception
end
