require 'rubygems'
require 'sinatra'
require 'erb'
require 'json'
require 'right_aws'
require 'redis'
require 'uuid'
require 'uri'

# export VOLDEMORT_STORE="kontexa"
# export VOLDEMORT_ADDRESS="localhost:6666"
# export MEMCACHED_ADDRESS="localhost:11211"

sqs = RightAws::SqsGen2.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
queue = RightAws::SqsGen2::Queue.new(sqs, 'kontexa_test')
queue.clear() # Dev only!

redis_uri = URI.parse(ENV["REDISTOGO_URL"])
REDIS = Redis.new(:host => redis_uri.host, :port => redis_uri.port, :password => redis_uri.password)

uuid_factory = UUID.new

get '/' do
  " "
end

post '/email' do  
  uuid = uuid_factory.generate
  puts "UUID: #{uuid}"
  json = JSON.generate(params)
  puts "###JSON### #{json}"
  REDIS.set(uuid, json)
  ['From', 'To', 'Cc', 'sender', 'subject', 'body-plain'].each do |key|
    puts "###{key}##  #{params[key]}"
  end
  
  # Need to put the identity of the user of the service here, reliably, somehow, appended to the uuid?
  queue.push uuid
  "true"
end
