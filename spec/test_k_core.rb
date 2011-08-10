#!/usr/bin/env jruby

require 'lib/graph_client'
require 'jcode'
$KCODE = 'UTF8'

graph_client = GraphClient.new ENV['VOLDEMORT_STORE'], ENV['VOLDEMORT_ADDRESS']
graph = graph_client.get 'imap:russell.jurney@gmail.com'

original_v = graph.v.count
original_e = graph.e.count

graph.k_core! 2
puts "Original Graph: Vertices: #{original_v} Edges: #{original_e}"
puts "2-Core Graph: Vertices: #{graph.v.count} Edges: #{graph.e.count}"
