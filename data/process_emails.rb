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

user_name = "russell.jurney@gmail.com"

SQS = RightAws::SqsGen2.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
queue = RightAws::SqsGen2::Queue.new(SQS, 'kontexa_test')

redis_uri = URI.parse(ENV["REDISTOGO_URL"])
redis = Redis.new(:host => redis_uri.host, :port => redis_uri.port, :password => redis_uri.password)

graph_client = GraphClient.new ENV['VOLDEMORT_STORE'], ENV['VOLDEMORT_ADDRESS'], ENV['MEMCACHED_ADDRESS']
graph = EmailGraph.new
restart_json = graph_client.get user_name
if restart_json
  graph.from_json!
end

interrupted = false

trap("SIGINT") { interrupted = true }

system 'rm /tmp/email.graphml'

count = 0

while(true) do
  # Trap ctrl-c 
  if interrupted
    system 'rm /tmp/email.graphml'
    graph.export '/tmp/email.graphml'
    graph_client.set user_name, graph.to_json
    exit
  end
    
  uuid = queue.pop
  if uuid and uuid.body
    json = redis.get uuid.body
    puts json
    email = JSON.parse json
    
    # Update the graph with this new email information.
    from_address = strip_address email['From']
    from = graph.find_or_create_vertex({:type => 'email', :address => from_address}, :address)
    
    to_addresses = split_addresses(email['To'])
    to_addresses.each do |to_address|
      email = strip_address to_address
        puts "#{from_address} --> #{email}"
      to = graph.find_or_create_vertex({:type => 'email', :address => email}, :address)
      edge = graph.find_or_create_edge(from, to, 'sent')
      props = edge.properties || {}
      props.merge!({ 'volume' => ((props['volume'] || 0) + 1) })
      edge.properties = props
    end
    
    puts "email['Cc'] field is: #{email['Cc']} | #{email['cc']}"
    if email['Cc']
      cc_addresses = split_addresses(email['Cc'])
      cc_addresses.each do |cc_address|        
        email = strip_address cc_address
          puts "#{from_address} --> #{email}"
        cc = find_or_create_vertex({:type => 'email', :address => email}, :address)
        edge = graph.find_or_create_edge(from, cc, 'sent')
        props = edge.properties || {}
        props.merge!({ 'volume' => ((props['volume'] || 0) + 1) })
        edge.properties = props
      end
    end

    # For now - for debug, I am not removing emails from redis
    #redis.set uuid, nil
    if (count % 10) == 0
      puts "Saving!"
      system 'rm -f /tmp/email.graphml'
      graph.export '/tmp/email.graphml'
      graph_client.set "russell.jurney@gmail.com", graph
    end
    count += 1
  end
  
  sleep 1
end
