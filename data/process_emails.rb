require 'rubygems'
require 'erb'
require 'json'
require 'right_aws'
require 'redis'
require 'uuid'
require 'uri'
require 'pacer'
require 'lib/graph_client'
require 'lib/graph_helper'
require 'data/email'

SQS = RightAws::SqsGen2.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
queue = RightAws::SqsGen2::Queue.new(SQS, 'kontexa_test')

redis_uri = URI.parse(ENV["REDISTOGO_URL"])
REDIS = Redis.new(:host => redis_uri.host, :port => redis_uri.port, :password => redis_uri.password)

GRAPH_CLIENT = GraphClient.new ENV['VOLDEMORT_STORE'], ENV['VOLDEMORT_ADDRESS'], ENV['MEMCACHED_ADDRESS']
graph = Pacer.tg

# Now that we are printing the graphs, populate a graph from this input.

while(1) do
  uuid = queue.pop
  if uuid and uuid.body
    json = REDIS.get uuid.body
    email = JSON.parse json
    
    parsed = {}
    
    parsed['From'] = extract_email strip_address email['From']
    from = nil
    if graph.v(:address =>  email['From']).empty?
      from = graph.create_vertex(:type => 'email', :address => email['From'])
    else
      from = graph.v(:address =>  email['From'])
    end
    
    parsed['To'] = split_addresses(email['To'])
    parsed['To'].each do |to| 
      puts "#{extract_email parsed['From']} --> #{extract_email to}"
      to = nil
      if graph.v(:address =>  email['To']).empty?
        to = graph.create_vertex(:type => 'email', :address => email['To'])
      else
        to = graph.v(:address =>  email['To'])
      end
      # Must increment if not already there graph.create_edge nil, from, to, :sent, {}
    end
    
    if email['Cc']
      parsed['Cc'] = split_addresses(email['Cc'])
      parsed['Cc'].each do |cc| 
        puts "#{extract_email parsed['From']} --> #{extract_email cc}"
        
      end
    end

    REDIS.set uuid, nil
  end
  sleep 1
end
