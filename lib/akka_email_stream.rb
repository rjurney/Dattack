require 'rubygems'
require 'json'
require 'right_aws'
require 'redis'
require 'uuid'
require 'uri'
require 'pacer'
require 'tmail'
require 'lib/graph_client'
require 'lib/email_graph'
require 'lib/util'
require 'jcode'
require 'lib/akka'

$KCODE = 'UTF8'

require 'java'
module Akka
  include_package 'se.scalablesolutions.akka.actor'
end

# The Poll actor queries SQS every second or two (fallback strategy later), and stashes the emails it pulls in redis
# before notifying a parser to parse the email.
class SQSPollActor < Akka::UntypedActor
  attr_reader :sqs, :queue, :redis

  def self.create(*args)
    self.new(*args)
  end

  def preStart
     @sqs = RightAws::SqsGen2.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
     @queue = RightAws::SqsGen2::Queue.new(@sqs, 'kontexa_test')
     
     redis_uri = URI.parse(ENV["REDISTOGO_URL"])
     @redis = Redis.new(:host => redis_uri.host, :port => redis_uri.port, :password => redis_uri.password)
  end
  
  def start
     super.start
     poll_loop
  end
  
  def poll_loop
     while(true)
        uuid = poll
        if uuid
          # Spawn an actor to render the email.
          puts "!!! Acted on: #{uuid.body}"
          #sendMessage(res.body)
        else
          delay
        end
     end
  end
  
  def poll
     uuid = @queue.pop
     if uuid.respond_to?('body') and uuid.body
        uuid.body
     else
        nil
     end
  end
  
  def delay
     sleep 1
  end

  def onReceive(message)
    puts "!!! Acted on: #{message}"
  end
end

actor = Akka::UntypedActor.actorOf(SQSPollActor).start
# actor.sendOneWay "hello actor world"
# sleep 10
# Akka::ActorRegistry.shutdownAll
puts "HI!"