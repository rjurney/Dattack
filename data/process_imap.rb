# The purpose of this library is to access emails via IMAP - the Inbox and Outbox
require 'net/imap'
require 'tmail'
require 'json'
require 'uri'
require 'data/email'
require 'lib/graph_client'

PREFIX = "historic:"
USERNAME = "russell.jurney@gmail.com"
USERKEY = PREFIX + USERNAME

# Graph and persistence in Voldemort
graph_client = GraphClient.new ENV['VOLDEMORT_STORE'], ENV['VOLDEMORT_ADDRESS'], ENV['MEMCACHED_ADDRESS']
hist_graph = EmailGraph.new

(tmp_graph = graph_client.get USERKEY).nil? ? hist_graph : hist_graph = tmp_graph

# Trap ctrl-c
interrupted = false
trap("SIGINT") { interrupted = true }

count = 0

# Account setup
imap = Net::IMAP.new('imap.gmail.com',993,true)
imap.login(USERNAME, ENV['GMAILPASS'])

# First check the OUTBOX
imap.examine('[Gmail]/Sent Mail') # examine is read only
imap.search(['ALL']).each do |message_id|
  
  # Trap ctrl-c 
  if interrupted
    puts "Saving..."
    system 'rm /tmp/historic_email.graphml'
    hist_graph.export '/tmp/historic_email.graphml'
    graph_client.set USERKEY, hist_graph
    exit
  end
  
  msg = imap.fetch(message_id,'RFC822')[0].attr['RFC822']
  mail = TMail::Mail.parse(msg)
  from_addresses = mail.header['from'].addrs
  to_addresses = mail.header['to'].addrs
  
  from_addresses.each do |from|
    to_addresses.each do |to|
      puts "#{from.address} --> #{to.address} [to]"
    end
  
    if mail.header['cc']
      cc_addresses = mail.header['cc'].addrs
      cc_addresses.each do |cc|
        puts "#{from.address} --> #{cc.address} [cc]"
      end
    end
    
    if mail.header['bcc']
      bcc_addresses = mail.header['bcc'].addrs
      bcc_addresses.each do |bcc|
        puts "#{from.address} --> #{bcc.address} [bcc]"
      end
    end
  end
  
  if (count % 100) == 0
    puts "Saving..."
    system 'rm -f /tmp/historic_email.graphml'
    hist_graph.export '/tmp/historic_email.graphml'
    puts hist_graph
    graph_client.set USERKEY, hist_graph
  end
  count += 1
  
end

# Now check the INBOX
count = 0

imap.examine('INBOX') # examine is read only
imap.search(['ALL']).each do |message_id|
  
  # Trap ctrl-c 
  if interrupted
    puts "Saving..."
    system 'rm /tmp/historic_email.graphml'
    hist_graph.export '/tmp/historic_email.graphml'
    graph_client.set USERKEY, hist_graph
    exit
  end
  
  msg = imap.fetch(message_id,'RFC822')[0].attr['RFC822']
  mail = TMail::Mail.parse(msg)
  from_addresses = mail.header['from'].addrs
  to_addresses = mail.header['to'].addrs
  
  from_addresses.each do |from|
    to_addresses.each do |to|
      puts "#{from.address} --> #{to.address} [to]"
    end
  
    if mail.header['cc']
      cc_addresses = mail.header['cc'].addrs
      cc_addresses.each do |cc|
        puts "#{from.address} --> #{cc.address} [cc]"
      end
    end
    
    if mail.header['bcc']
      bcc_addresses = mail.header['bcc'].addrs
      bcc_addresses.each do |bcc|
        puts "#{from.address} --> #{bcc.address} [bcc]"
      end
    end
  end
  
  if (count % 100) == 0
    puts "Saving..."
    system 'rm -f /tmp/historic_email.graphml'
    hist_graph.export '/tmp/historic_email.graphml'
    puts hist_graph
    graph_client.set USERKEY, hist_graph
  end
  count += 1
end

def check_email_addresses(addresses)
  addresses.split(/,\s*/).each do |email| 
    unless email =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i
      puts "are invalid -- #{email}"
    end
  end
end