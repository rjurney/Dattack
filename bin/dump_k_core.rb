#!/usr/bin/env jruby

require 'lib/graph_client'
require 'jcode'
$KCODE = 'UTF8'
require 'optparse'

unless ARGV[0] and ARGV[1]
  puts "Usage: bin/dump_k_core <voldemort_email_key> <k> <output_directory>"
  exit
end

USERKEY = ARGV[0];
K = ARGV[1];
OUT_DIRECTORY = ARGV[2] || '/tmp/'

# Graph and persistence in Voldemort
graph_client = GraphClient.new ENV['VOLDEMORT_STORE'], ENV['VOLDEMORT_ADDRESS']
graph = EmailGraph.new

(tmp_graph = graph_client.get USERKEY).nil? ? graph : graph = tmp_graph

graph.k_core! K.to_i

# Write to graphml
graph.export "#{OUT_DIRECTORY}/#{USERKEY}-#{K}-core.graphml"
