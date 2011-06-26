require 'rubygems'
require 'erb'
require 'json'
require 'right_aws'
require 'redis'
require 'uuid'
require 'uri'
require 'pacer'
require 'tmail'
require 'lib/graph_client'
require 'data/email'
require 'lib/email_graph'

SQS = RightAws::SqsGen2.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
queue = RightAws::SqsGen2::Queue.new(SQS, 'kontexa_test')

redis_uri = URI.parse(ENV["REDISTOGO_URL"])
redis = Redis.new(:host => redis_uri.host, :port => redis_uri.port, :password => redis_uri.password)

graph_client = GraphClient.new ENV['VOLDEMORT_STORE'], ENV['VOLDEMORT_ADDRESS'], ENV['MEMCACHED_ADDRESS']
graph = EmailGraph.new

interrupted = false

trap("SIGINT") { interrupted = true }

system 'rm /tmp/email.graphml'

count = 0

while(count < 100) do
  # Trap ctrl-c 
  if interrupted
    system 'rm /tmp/email.graphml'
    graph.export '/tmp/email.graphml'
    graph_client.set "russell.jurney@gmail.com", graph.to_json
    exit
  end
    
  uuid = queue.pop
  if uuid and uuid.body
    json = redis.get uuid.body
    email = JSON.parse json
    
    vertices = {}
    
    # Update the graph with this new email information.
    from_address = strip_address email['From']
    from = graph.find_or_create_vertex({:type => 'email', :address => from_address}, :type)
    
    to_addresses = split_addresses(email['To'])
    to_addresses.each do |to_address| 
      email = strip_address to_address
      to = graph.find_or_create_vertex({:type => 'email', :address => email}, :type)
      graph.find_or_create_edge(from, to, 'sent', 'volume', 1)
      puts "#{from_address} --> #{email}"
    end
    
    if email['Cc']
      cc_addresses = split_addresses(email['Cc'])
      cc_addresses.each do |cc_address| 
        email = strip_address cc_address
        cc = find_or_create_vertex({:type => 'email', :address => email}, :type)
        graph.find_or_create_edge(from, cc, 'sent', 'volume', 1)
        puts "#{from_address} --> #{email}"
      end
    end

    redis.set uuid, nil
    if (count % 10) == 0
      puts "Saving!"
      system 'rm /tmp/email.graphml'
      graph.export '/tmp/email.graphml'
      graph_client.set "russell.jurney@gmail.com", graph
    end
    count += 1
  end
  
  sleep 1
end
