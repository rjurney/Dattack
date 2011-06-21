# 
# This class is a graph getter against voldemort. It parses JSON graphs into
# TinkerGraph ojects, and stores these objects, which contain indexes, in 
# memcache, thereafter fetching from the cache directly.
#

require 'rubygems'
require 'voldemort-rb'
require 'memcache'
require 'pacer'

class GraphClient
	attr_reader :voldemort, :memcache, :raw
	
	def initialize(voldemort_store, voldemort_address, memcache_address)
		# Connections settable in environment.rb
		@voldemort = VoldemortClient.new voldemort_store, voldemort_address
		@memcache = MemCache.new memcache_address
		@memcache.flush_all
		@raw = true
	end
	
	def get_graph_object(key)
		return_graph get key
	end
	
	def get_graph(key)
		graph = nil
		begin
			graph = return_graph @memcache.get key, @raw
		rescue
			graph = nil
		end
		
		if graph.nil?
			begin
				graph = return_graph @voldemort.get key
				if not graph.nil?
					@memcache.set key, graph, 0, true
				end
			rescue
			end
		end
		graph
	end
	
	def get_graph_json(key)
		@voldemort.get key
	end
	
	def set_graph(key, value)
		@voldemort.put key, value.to_json
		@memcache.set key, value, 0, @raw
	end
	
	def return_graph(input)
		if input.is_a? Java::ComTinkerpopBlueprintsPgmImplsTg::TinkerGraph
			return input
		else
			graph = Pacer.tg
			graph.from_json! input
			return graph
		end
	end
	
end