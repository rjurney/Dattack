# 
# This class is a graph getter against voldemort. It parses JSON graphs into
# TinkerGraph ojects, and stores these objects, which contain indexes, in 
# memcache, thereafter fetching from the cache directly.
#
 
require 'rubygems'
require 'voldemort-rb'
require 'pacer'
require 'lib/email_graph'
require 'jcode'
$KCODE = 'UTF8'

class GraphClient
	attr_reader :voldemort, :memcache, :raw
	
	def initialize(voldemort_store, voldemort_address)
		# Connections settable in environment.rb
		@voldemort = VoldemortClient.new voldemort_store, voldemort_address
		@raw = true
	end
	
	JSON_ESCAPE_MAP = {
        '\\'    => '\\\\',
        '</'    => '<\/',
        "\r\n"  => '\n',
        "\n"    => '\n',
        "\r"    => '\n',
        '"'     => '\\"' }
        
	def escape_json(json)
    json.gsub(/(\\|<\/|\r\n|[\n\r"])/) { JSON_ESCAPE_MAP[$1] }
  end
	
	def get(key)
		graph = return_graph get_json key
	end
	
	def get_json(key)
		@voldemort.get key
	end
	
	def set(key, graph)
	  set_json key, escape_json(graph.to_json)
	end
	
	def set_json(key, value)
	  escaped_value = 
		@voldemort.put key, escaped_value
	end
	
	def delete(key)
	  @voldemort.delete key
	end
	
	def del(key)
	  delete(key)
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
	
	# Helps with debug - writes what is in voldemort
	def write_voldemort_json(key)
	  json = @voldemort.get key
	  filename = '/tmp/' + key + '.json'
	  File.open(filename, 'w') {|f| f.write(json) }
	  filename
	end
	
	def test_json(key)
	  path = write_voldemort_json key
	  output = `env cat #{path}|json_xs`
	  puts output
	end
	
end