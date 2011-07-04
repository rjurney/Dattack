# 
# This class is a graph getter against voldemort. It parses JSON graphs into
# TinkerGraph ojects, and stores these objects, which contain indexes, in 
# memcache, thereafter fetching from the cache directly.
#
$KCODE = 'UTF8'
 
require 'rubygems'
require 'voldemort-rb'
require 'pacer'
require 'lib/email_graph'

class GraphClient
	attr_reader :voldemort, :memcache, :raw
	
	def initialize(voldemort_store, voldemort_address, memcache_address)
		# Connections settable in environment.rb
		@voldemort = VoldemortClient.new voldemort_store, voldemort_address
		@raw = true
	end
	
	def get(key)
		graph = return_graph get_json key
	end
	
	def get_json(key)
		@voldemort.get key
	end
	
	def set(key, graph)
	  set_json key, graph.to_json
	end
	
	def set_json(key, value)
		@voldemort.put key, value
	end
	
	def delete(key)
	  @voldemort.delete key
	end
	
	def return_graph(input)
	  if input.nil? or input.empty?
	    return nil
		elsif input.is_a? EmailGraph
			return input
		else
			graph = EmailGraph.new
			graph.from_json! input
			return graph
		end
	end
	
end