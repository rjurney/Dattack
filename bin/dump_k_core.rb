#!/usr/bin/env jruby

require 'lib/graph_client'
require 'jcode'
$KCODE = 'UTF8'
require 'optparse'

unless ARGV[0] and ARGV[1]
  puts "Usage: bin/dump_k_core <email> <k> <output_directory>"
  exit
end

user_key = 'imap:' + ARGV[0]
k = ARGV[1]
out_dir = ARGV[2] || '/tmp/'

# Graph and persistence in Voldemort
graph_client = GraphClient.new ENV['VOLDEMORT_STORE'], ENV['VOLDEMORT_ADDRESS']
graph = graph_client.get user_key

graph.wk_core! k.to_i

# Write to graphml
graph.export "#{out_dir}/#{user_key}-#{k}-core.graphml"
