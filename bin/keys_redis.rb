#!/usr/bin/env jruby

require 'rubygems'
require 'uri'
require 'redis'

# Warning - this deletes all keys from redis!
redis_uri = URI.parse(ENV["REDISTOGO_URL"])
redis = Redis.new(:host => redis_uri.host, :port => redis_uri.port, :password => redis_uri.password)

(redis.keys '*').each {|key| value = redis.get key; puts "[ #{key} ]"}

puts "Total signups: #{redis.keys.size}"