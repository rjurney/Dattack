#!/usr/bin/env jruby

require 'rubygems'
require 'uri'
require 'redis'

unless ARGV[0] and ARGV[1]
  puts 'Usage: bin/remove_redis_key key value'
  exit
end

key = ARGV[0]
value = ARGV[1]

# Warning - this deletes all keys from redis!
redis_uri = URI.parse(ENV["REDISTOGO_URL"])
redis = Redis.new(:host => redis_uri.host, :port => redis_uri.port, :password => redis_uri.password)

redis.set key, value
puts redis.get key
