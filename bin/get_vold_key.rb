#!/usr/bin/env jruby

require 'lib/graph_client'
require 'jcode'
$KCODE = 'UTF8'
require 'optparse'

unless ARGV[0]
  puts "Usage: bin/vold_to_graphml <voldemort_key>"
  exit
end

USERKEY = ARGV[0];

# Graph and persistence in Voldemort
graph_client = GraphClient.new ENV['VOLDEMORT_STORE'], ENV['VOLDEMORT_ADDRESS']
graph = EmailGraph.new

puts graph_client.get USERKEY
