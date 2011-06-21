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

SQS = RightAws::SqsGen2.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
queue = RightAws::SqsGen2::Queue.new(SQS, 'kontexa_test')

redis_uri = URI.parse(ENV["REDISTOGO_URL"])
REDIS = Redis.new(:host => redis_uri.host, :port => redis_uri.port, :password => redis_uri.password)

GRAPH_CLIENT = GraphClient.new ENV['VOLDEMORT_STORE'], ENV['VOLDEMORT_ADDRESS'], ENV['MEMCACHED_ADDRESS']

while(1) do
  uuid = queue.pop
  if uuid
    json = REDIS.get uuid
    email = JSON.parse json
    
    parsed = {}
    parsed['From'] = extract_email strip_address email['From']
    parsed['To'] = split_addresses(email['To'])
    
    parsed['To'].each {|to| puts "#{extract_email parsed['From']} --> #{to}"}
    if email['Cc']
      parsed['Cc'] = split_addresses(email['Cc'])
      parsed['Cc'].each {|cc| puts "#{extract_email parsed['From']} --> #{cc}"}
    end

    #REDIS.set uuid, nil
  end
  sleep 1
end
