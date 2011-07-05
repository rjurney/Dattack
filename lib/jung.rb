# Hooking up JUNG to TinkerGraph
require 'pacer'
require 'java'

require 'lib/java/blueprints-core-0.8.jar'
require 'lib/java/blueprints-graph-jung-0.8.jar'
require 'lib/java/jung-graph-impl-2.0.1.jar'
require 'lib/java/jung-algorithms-2.0.1.jar'

java_import 'com.tinkerpop.blueprints.pgm.oupls.GraphSource'
java_import 'com.tinkerpop.blueprints.pgm.oupls.jung.GraphJung'
java_import 'edu.uci.ics.jung.algorithms.scoring.PageRank'

graph = Pacer.tg

jg = GraphJung.new graph

pr = PageRank.new(jg, 0.15)

# But all scores are even?
jg.get_vertices.collect{|v| [v, pr.get_vertex_score(v)]}