# The purpose of this library is to access emails via IMAP, and to build a graph out of them
# 
# Usage: jruby lib/process_imap.sh <username@gmail.com>
#

require 'net/imap'
require 'tmail'
require 'json'
require 'uri'
require 'redis'
require 'lib/graph_client'
require 'lib/email_graph'
require 'gmail_xoauth'
require 'jwz_threading'

require 'jcode'
$KCODE = 'UTF8'

class ProcessImap

  attr_accessor :redis, :imap, :graph, :graph_client, :user_key, :user_email, :folder, :interrupted, :message_count
  PREFIX = "imap:"
  
  def initialize(user_email, message_count)
    @user_email = user_email
    @user_key = PREFIX + user_email
    @message_count = message_count.to_i

    # Trap ctrl-c
    @interrupted = false
    trap("SIGINT") { @interrupted = true }

    # Graph and persistence in Voldemort
    @graph_client = GraphClient.new ENV['VOLDEMORT_STORE'], ENV['VOLDEMORT_ADDRESS']
    @graph = EmailGraph.new

    # Setup redis
    redis_uri = URI.parse(ENV["REDISTOGO_URL"])
    @redis = Redis.new(:host => redis_uri.host, :port => redis_uri.port, :password => redis_uri.password)
  end

  def scan_folder
    count = 0
    skipped_ids = []
    @folder = '[Gmail]/All Mail'
    self.new_imap
 
    messages = imap.search(['ALL'])
    messages = messages.reverse # Most recent first

    @graph_client.voldemort.get "resume_id:#{@user_email}"
    resume_id = [(resume_id.to_i - 1), 0].max
    if resume_id
      puts "Resuming from #{resume_id}"
      messages = messages[resume_id..@message_count]
    else
      # Flush the user's imap records
      @graph_client.del @user_key
    end

    messages[resume_id..@message_count].each do |message_id|
      # Trap ctrl-c to persist
      if @interrupted
        self.save_state message_id
        exit
      end

      # Fetch the message
      begin
        msg = @imap.fetch(message_id,'RFC822.HEADER')[0].attr['RFC822.HEADER']
        mail = TMail::Mail.parse(msg)
        # No from node - skip
        next unless mail.header['from'] and mail.header['from'].respond_to? 'addrs'
    
        # Get a count of all edges to get a divisor for outgoing edge weights
        recipient_count = count_recipients mail
        from_addresses = mail.header['from'].addrs
        unless from_addresses
          puts "Skipped email without a from address!"
          skipped_ids << message_id
          next
        end
      rescue Exception => e
        skipped_ids << message_id
        puts e.message + e.backtrace.join("\n")
        next
      end
  
      # Build connection graph from recipients
      begin
        from_addresses.each do |t_from|
          from_address = t_from.address.downcase.gsub /"/, '' #"
          from = @graph.find_or_create_vertex({:type => 'email', :Label => from_address, :network => @user_email}, :Label)
      
          self.build_connections from_address, from, mail, recipient_count, message_id
        end

        # Persist to Voldemort as JSON and /tmp as graphml every 100 emails processed
        if ((count % 100) == 0) and (count > 0)
          self.save_state message_id
        end
    
      rescue Exception => e
        puts "Exception parsing email: #{e.class} #{e.message} #{e.backtrace}}"
        skipped_ids << message_id
        next
      # IMAP connections die. Ressucitate.
      rescue EOFError, IOError, Error => e
        puts "Error parsing email: #{e.class} #{e.message}"
        skipped_ids << message_id
        self.new_imap    
        # next removed for now
      end
      count += 1
    end

    # Final save!
    self.save_state nil
    @graph_client.voldemort.delete "resume_id:#{@user_email}"
    puts "Skipped IDs: #{skipped_ids}"
  end
  
  def save_state(message_id=nil)
    puts "Saving... #{graph}"
    
    # Graphml
    system "rm /tmp/#{user_key}.graphml"
    @graph.export "/tmp/#{user_key}.graphml"
    # JSON -> /tmp
    @graph_client.write_voldemort_json @user_key
    # Voldemort as JSON
    @graph_client.set @user_key, @graph
    # Save the message_id we are on for resume, unless we're all done
    @graph_client.voldemort.put "resume_id:#{@user_email}", message_id.to_s if message_id
  end
  
  def build_connections(from_address, from, mail, recipient_count, message_id)
	  for type in ['to', 'cc', 'bcc']
	    if mail.header[type] and mail.header[type].respond_to? 'addrs'
        to_addresses = mail.header[type].addrs
        to_addresses.each do |t_to|
          to_address = t_to.address.downcase.gsub /"/, '' #"
          to = @graph.find_or_create_vertex({:type => 'email', :Label => to_address, :network => @user_email}, :Label)
          edge, status = @graph.find_or_create_edge(from, to, 'sent')
          props = edge.properties || {}
          added_weight = 1.0/(recipient_count||1.0)
          to['Weight'] ||= 0
          to['Weight'] += added_weight
          # Ugly as all hell, but JSON won't let you have a numeric key in an object...
          props.merge!({ 'Weight' => ((props['Weight'].to_i || 0) + added_weight).to_s })
          edge.properties = props
          puts "[#{message_id}] #{from_address} --> #{to_address} [#{type}] #{props['Weight']}"
        end
      end
    end
	end
	
	def new_imap
    @imap.close if @imap and @imap.respond_to? 'close'
    @imap = Net::IMAP.new('imap.gmail.com', 993, usessl = true, certs = nil, verify = false)
	  consumer_key = ENV["CONSUMER_KEY"] || ENV["consumer_key"]
	  consumer_secret = ENV["CONSUMER_SECRET"] || ENV["consumer_secret"]
	  token_json = @redis.get 'access_token:' + @user_email
	  token = JSON token_json
	  @imap.authenticate('XOAUTH', @user_email,
 	    :consumer_key => consumer_key,
 	    :consumer_secret => consumer_secret,
  	  :token => token['token'],
  	  :token_secret => token['secret']
	  )
	  @imap.examine(@folder) # examine is read only
	end
	
	def count_recipients(mail)
	  recipient_count = 0
    for to in ['to', 'cc', 'bcc']
      if mail.header[to] and mail.header[to].respond_to? 'addrs'
        to_addresses = mail.header[to].addrs
        recipient_count += to_addresses.size
      end
    end
    recipient_count
  end
	
end