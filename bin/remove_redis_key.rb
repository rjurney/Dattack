#!/usr/bin/env jruby

require 'rubygems'
require 'uri'
require 'redis'

unless ARGV[0]
  puts 'Usage: bin/remove_redis_key key'
  exit
end

key = ARGV[0]

# Warning - this deletes all keys from redis!
redis_uri = URI.parse(ENV["REDISTOGO_URL"])
redis = Redis.new(:host => redis_uri.host, :port => redis_uri.port, :password => redis_uri.password)

puts redis.get key
puts redis.del key