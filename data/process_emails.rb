require 'rubygems'
require 'erb'
require 'json'
require 'right_aws'
require 'redis'
require 'uuid'
require 'uri'
require 'pacer'
require 'lib/graph_client'
require 'data/email'
require 'lib/email_graph'

SQS = RightAws::SqsGen2.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
queue = RightAws::SqsGen2::Queue.new(SQS, 'kontexa_test')

redis_uri = URI.parse(ENV["REDISTOGO_URL"])
REDIS = Redis.new(:host => redis_uri.host, :port => redis_uri.port, :password => redis_uri.password)

GRAPH_CLIENT = GraphClient.new ENV['VOLDEMORT_STORE'], ENV['VOLDEMORT_ADDRESS'], ENV['MEMCACHED_ADDRESS']
graph = Pacer.tg

while(1) do
  uuid = queue.pop
  if uuid and uuid.body
    json = REDIS.get uuid.body
    email = JSON.parse json
    
    vertices = {}
    
    # Update the graph with this new email information.
    from_address = extract_email strip_address email['From']
    from = graph.find_or_create_vertex {:type => 'email', :address => from_address}, :type
    
    to_addresses = split_addresses(email['To'])
    to_addresses.each do |to_address| 
      email = extract_email to_address
      to = graph.find_or_create_vertex {:type => 'email', :address => email}, :type
      graph.find_or_increment_edge nil, from, to, 'sent', {volume => 1}
    end
    
    if email['Cc']
      cc_addresses = split_addresses(email['Cc'])
      cc_addresses.each do |cc_address| 
        email = extract_email cc_address
        cc = find_or_create_vertex {:type => 'email', :address => email}, :type
        graph.find_or_increment_edge nil, from, cc, 'sent', {volume => 1}
      end
    end

    REDIS.set uuid, nil
  end
  sleep 1
end
