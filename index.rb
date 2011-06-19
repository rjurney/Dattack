require 'rubygems'
require 'sinatra'
require 'erb'
require 'json'
require 'right_aws'
require 'redis'

sqs = RightAws::SqsGen2.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
queue = RightAws::SqsGen2::Queue.new(sqs, 'kontexa_test')
queue.clear() # Dev only!

redis_uri = URI.parse(ENV["REDISTOGO_URL"])
REDIS = Redis.new(:host => redis_uri.host, :port => redis_uri.port, :password => redis_uri.password)

get '/' do
  " "
end

post '/email' do
  puts "ID is: #{params[:subject]}"
  puts "Incoming Email Post: "
  params.each {|key, value| puts "Key: #{key} Value: #{value}"}
  
  queue.push JSON params

  "true"
end
