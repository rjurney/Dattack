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
require 'lib/email_mixin'
require 'gmail_xoauth'
require 'jcode'
$KCODE = 'UTF8'

include EmailMixin

process_args

PREFIX = "imap:"
USERNAME = ARGV[0]
USERKEY = PREFIX + USERNAME
MESSAGE_COUNT = 5000

# Trap ctrl-c
interrupted = false
trap("SIGINT") { interrupted = true }

# Graph and persistence in Voldemort
@graph_client = GraphClient.new ENV['VOLDEMORT_STORE'], ENV['VOLDEMORT_ADDRESS']
@graph = EmailGraph.new

# Setup redis
redis_uri = URI.parse(ENV["REDISTOGO_URL"])
@redis = Redis.new(:host => redis_uri.host, :port => redis_uri.port, :password => redis_uri.password)

count = 0
skipped_ids = []
folder = '[Gmail]/All Mail'
@imap = new_imap
 
messages = imap.search(['ALL'])
messages = messages.reverse # Most recent first

@graph_client.voldemort.get "resume_id:#{USERKEY}"
resume_id = [(resume_id.to_i - 1), 0].max
if resume_id
  messages = messages[resume_id..MESSAGE_COUNT]
else
  # Flush the user's imap records
  @graph_client.del USERKEY
end

messages[resume_id..MESSAGE_COUNT].each do |message_id|
  # Trap ctrl-c to persist
  if interrupted
    save_state
    exit
  end

  # Fetch the message
  begin
    msg = imap.fetch(message_id,'RFC822.HEADER')[0].attr['RFC822.HEADER']
    mail = TMail::Mail.parse(msg)
    # No from node - skip
    next unless mail.header['from'] and mail.header['from'].respond_to? 'addrs'
    
    # Get a count of all edges to get a divisor for outgoing edge weights
    recipient_count = count_recipients
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
      from = graph.find_or_create_vertex({:type => 'email', :address => from_address, :network => USERNAME}, :address)
      
      build_connections(['to', 'cc', 'bcc'], mail)
    end

    # Persist to Voldemort as JSON and /tmp as graphml every 100 emails processed
    if ((count % 100) == 0) and (count > 0)
      save_state
    end
    
  rescue Exception => e
    puts "Exception parsing email: #{e.class} #{e.message} #{e.backtrace}}"
    skipped_ids << message_id
    next
  # IMAP connections die. Ressucitate.
  rescue EOFError, IOError, Error => e
    puts "Error parsing email: #{e.class} #{e.message}"
    skipped_ids << message_id
    @imap = new_imap    
    # next removed for now
  end
  count += 1
end

# Final save!
save_state
@graph_client.voldemort.delete "resume_id:#{USERKEY}"

puts "Skipped IDs: #{skipped_ids}"
