#!/usr/bin/env jruby

require 'lib/graph_client'
require 'jcode'
$KCODE = 'UTF8'
require 'optparse'

unless ARGV[0]
  puts "Usage: bin/vold_to_graphml <voldemort_email_key>, <output_directory>"
  exit
end

USERKEY = ARGV[0]; OUT_DIRECTORY = ARGV[1] || '/tmp/'

# Graph and persistence in Voldemort
graph_client = GraphClient.new ENV['VOLDEMORT_STORE'], ENV['VOLDEMORT_ADDRESS']
graph = EmailGraph.new

(tmp_graph = graph_client.get USERKEY).nil? ? graph : graph = tmp_graph

# Write to graphml
graph.export "#{OUT_DIRECTORY}/#{USERKEY}.graphml"
