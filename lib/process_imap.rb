# The purpose of this library is to access emails via IMAP - the Inbox and Outbox
# 
# Usage: jruby lib/process_imap.sh <username@gmail.com> <password>
#

require 'net/imap'
require 'tmail'
require 'json'
require 'uri'
require 'lib/graph_client'
require 'lib/email_graph'
require 'lib/util'
require 'jcode'
require 'redis'
require 'gmail_xoauth'

$KCODE = 'UTF8'

unless(ARGV[0] || ENV['GMAIL_USERNAME'])
  puts "Must supply gmail username as 1st argument, or set ENV['GMAIL_USERNAME']"
  exit
end

# unless(ARGV[1] || ENV['GMAILPASS'])
#   puts "Must supply gmail password as 2nd argument, or set ENV['GMAILPASS']"
#   exit
# end

unless(ENV['VOLDEMORT_STORE'] && ENV['VOLDEMORT_ADDRESS'])
  puts "Must set ENV['VOLDEMORT_STORE'] and ENV['VOLDEMORT_ADDRESS']"
  exit
end

PREFIX = "imap:"
USERNAME = ARGV[0] || ENV['GMAIL_USERNAME']
#PASSWORD = ARGV[1] || ENV['GMAILPASS']
USERKEY = PREFIX + USERNAME

# Graph and persistence in Voldemort
graph_client = GraphClient.new ENV['VOLDEMORT_STORE'], ENV['VOLDEMORT_ADDRESS']
graph = EmailGraph.new

# Trap ctrl-c
interrupted = false
trap("SIGINT") { interrupted = true }

count = 1

# Setup redis
redis_uri = URI.parse(ENV["REDISTOGO_URL"])
redis = Redis.new(:host => redis_uri.host, :port => redis_uri.port, :password => redis_uri.password)

# Account setup
imap = Net::IMAP.new('imap.gmail.com', 993, usessl = true, certs = nil, verify = false)
consumer_key = ENV["CONSUMER_KEY"] || ENV["consumer_key"]
consumer_secret = ENV["CONSUMER_SECRET"] || ENV["consumer_secret"]
token_json = redis.get 'access_token:' + USERNAME
token = JSON token_json
imap.authenticate('XOAUTH', USERNAME,
  :consumer_key => consumer_key,
  :consumer_secret => consumer_secret,
  :token => token['token'],
  :token_secret => token['secret']
)

skipped_ids = []
last_id = nil

# Temporary, gmail only
folders = ['[Gmail]/All Mail']

# Import all in-mail and all out-mail
folders.each do |folder|
  imap.examine(folder) # examine is read only  
  messages = imap.search(['ALL'])
  
  resume_id = graph_client.voldemort.get "resume_id:#{USERKEY}"
  resume_id = [(resume_id.to_i - 1), 0].max
  if resume_id
    messages = messages[resume_id..-1]
  else
    # Flush the user's imap records
    graph_client.del USERKEY
  end
  
  messages.each do |message_id|
    # Trap ctrl-c to persist
    if interrupted
      save_state(graph, USERKEY, graph_client, message_id)
      exit
    end
  
    begin
      msg = imap.fetch(message_id,'RFC822.HEADER')[0].attr['RFC822.HEADER']
      mail = TMail::Mail.parse(msg)
      from_addresses = mail.header['from'].addrs
      to_addresses = mail.header['to'].addrs
    rescue Exception => e
      skipped_ids << message_id
      puts e.message
      next
    end
    
    unless from_addresses
      puts "Skipped email without a from address!"
      skipped_ids << message_id
      next
    end
    
    begin 
      from_addresses.each do |t_from|
        from_address = t_from.address.downcase.gsub /"/, ''
        from = graph.find_or_create_vertex({:type => 'email', :address => from_address, :network => USERNAME}, :address)
        
        to_addresses.each do |t_to|
          to_address = t_to.address.downcase.gsub /"/, ''
          to = graph.find_or_create_vertex({:type => 'email', :address => to_address, :network => USERNAME}, :address)
          edge, status = graph.find_or_create_edge(from, to, 'sent')
          props = edge.properties || {}
          # Ugly as all hell, but JSON won't let you have a numeric key in an object...
          props.merge!({ 'volume' => ((props['volume'].to_i || 0) + 1).to_s })
          edge.properties = props
          puts "[#{message_id}] #{from_address} --> #{to_address} [to] #{props['volume']}"
        end
  
        if mail.header['cc']
          cc_addresses = mail.header['cc'].addrs
          cc_addresses.each do |t_cc|
            cc_address = t_cc.address.downcase.gsub /"/, ''
            cc = graph.find_or_create_vertex({:type => 'email', :address => (cc_address), :network => USERNAME}, :address)
            edge, status = graph.find_or_create_edge(from, cc, 'sent')
            props = edge.properties || {}
            # Ugly as all hell, but JSON won't let you have a numeric key in an object...
            props.merge!({ 'volume' => ((props['volume'].to_i || 0) + 1).to_s })
            edge.properties = props
            puts "[#{message_id}] #{from_address} --> #{cc_address} [cc] #{props['volume']}"
          end
        end
    
        if mail.header['bcc']
          bcc_addresses = mail.header['bcc'].addrs
          bcc_addresses.each do |t_bcc|
            bcc_address = b_cc.address.downcase.gsub /"/, ''
            bcc = graph.find_or_create_vertex({:type => 'email', :address => (bcc_address), :network => USERNAME}, :address)
            edge, status = graph.find_or_create_edge(from, bcc, 'sent')
            props = edge.properties || {}
            # Ugly as all hell, but JSON won't let you have a numeric key in an object...
            props.merge!({ 'volume' => ((props['volume'].to_i || 0) + 1).to_s })
            edge.properties = props          
            puts "[#{message_id}] #{from_address} --> #{bcc_address} [bcc] #{props['volume']}"
          end
        end
      end

      # Persist to Voldemort as JSON and /tmp as graphml every 100 emails processed
      if (count % 100) == 0
        save_state(graph, USERKEY, graph_client)
      end
      
    rescue Exception => e
      puts "Exception parsing email: #{e.class} #{e.message}}"
      skipped_ids << message_id
    # Temporary thing to get the class of the 'end of file reached' error that prints
    # After I find the class of the Error, I will handle it and re-initialize the IMAP
    # connection.
    rescue EOFError => e
      puts "Error parsing email: #{e.class} #{e.message}"
      skipped_ids << message_id
      imap = Net::IMAP.new('imap.gmail.com', 993, usessl = true, certs = nil, verify = false)
      consumer_key = ENV["CONSUMER_KEY"] || ENV["consumer_key"]
      consumer_secret = ENV["CONSUMER_SECRET"] || ENV["consumer_secret"]
      token_json = redis.get 'access_token:' + USERNAME
      token = JSON token_json
      imap.authenticate('XOAUTH', USERNAME,
        :consumer_key => consumer_key,
        :consumer_secret => consumer_secret,
        :token => token['token'],
        :token_secret => token['secret']
      )
      imap.examine(folder) # examine is read only  
      messages = imap.search(['ALL'])
      next
    rescue IOError => e
      puts "Error parsing email: #{e.class} #{e.message}"
      skipped_ids << message_id
      imap = Net::IMAP.new('imap.gmail.com', 993, usessl = true, certs = nil, verify = false)
      consumer_key = ENV["CONSUMER_KEY"] || ENV["consumer_key"]
      consumer_secret = ENV["CONSUMER_SECRET"] || ENV["consumer_secret"]
      token_json = redis.get 'access_token:' + USERNAME
      token = JSON token_json
      imap.authenticate('XOAUTH', USERNAME,
        :consumer_key => consumer_key,
        :consumer_secret => consumer_secret,
        :token => token['token'],
        :token_secret => token['secret']
      )
      imap.examine(folder) # examine is read only  
      messages = imap.search(['ALL'])
      next
    rescue Error => e
      puts "Error parsing email: #{e.class} #{e.message}"
      skipped_ids << message_id
      imap = Net::IMAP.new('imap.gmail.com', 993, usessl = true, certs = nil, verify = false)
      consumer_key = ENV["CONSUMER_KEY"] || ENV["consumer_key"]
      consumer_secret = ENV["CONSUMER_SECRET"] || ENV["consumer_secret"]
      token_json = redis.get 'access_token:' + USERNAME
      token = JSON token_json
      imap.authenticate('XOAUTH', USERNAME,
        :consumer_key => consumer_key,
        :consumer_secret => consumer_secret,
        :token => token['token'],
        :token_secret => token['secret']
      )
      imap.examine(folder) # examine is read only  
      messages = imap.search(['ALL'])
      next
    end
    count += 1
  end
end

# Final save!
save_state(graph, USERKEY, graph_client, nil)
