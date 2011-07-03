# The purpose of this library is to access emails via IMAP - the Inbox and Outbox
require 'net/imap'
require 'tmail'
require 'json'
require 'uri'
require 'data/email'
require 'lib/graph_client'
require 'lib/email_graph'

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

count = 1

# Account setup
imap = Net::IMAP.new('imap.gmail.com',993,true)
imap.login(USERNAME, ENV['GMAILPASS'])

skipped_ids = {}

# First check the OUTBOX

['INBOX','[Gmail]/Sent Mail'].each do |folder|
  skipped_ids[folder] = []
  
  imap.examine(folder) # examine is read only
  imap.search(['ALL']).each do |message_id|
  
    # Trap ctrl-c 
    if interrupted
      puts "Saving..."
      system 'rm /tmp/historic_email.graphml'
      hist_graph.export '/tmp/historic_email.graphml'
      graph_client.set USERKEY, hist_graph
      exit
    end
  
    begin
      msg = imap.fetch(message_id,'RFC822')[0].attr['RFC822']
      mail = TMail::Mail.parse(msg)
      from_addresses = mail.header['from'].addrs
      to_addresses = mail.header['to'].addrs
    rescue
      next
    end
    
    unless from_addresses
      puts "Skipped email without a from address!"
      next
    end
    
    begin 
      from_addresses.each do |t_from|
        from = hist_graph.find_or_create_vertex({:type => 'email', :address => t_from.address}, :address)
    
        to_addresses.each do |t_to|
          to = hist_graph.find_or_create_vertex({:type => 'email', :address => t_to.address}, :address)
          edge = hist_graph.find_or_create_edge(from, to, 'sent')
          props = edge.properties || {}
          props.merge!({ 'volume' => ((props['volume'].to_i || 0) + 1).to_s })
          edge.properties = props
          puts edge.to_json
          puts "[#{message_id}] #{t_from.address} --> #{t_to.address} [to]"
        end
  
        if mail.header['cc']
          cc_addresses = mail.header['cc'].addrs
          cc_addresses.each do |t_cc|
            cc = hist_graph.find_or_create_vertex({:type => 'email', :address => t_cc.address}, :address)
            edge = hist_graph.find_or_create_edge(from, cc, 'sent')
            props = edge.properties || {}
            props.merge!({ 'volume' => ((props['volume'].to_i || 0) + 1).to_s })
            edge.properties = props
            puts edge.to_json
            puts "[#{message_id}] #{t_from.address} --> #{t_cc.address} [cc]"
          end
        end
    
        if mail.header['bcc']
          bcc_addresses = mail.header['bcc'].addrs
          bcc_addresses.each do |t_bcc|
            bcc = hist_graph.find_or_create_vertex({:type => 'email', :address => t_bcc.address}, :address)
            edge = hist_graph.find_or_create_edge(from, bcc, 'sent')
            props = edge.properties || {}
            props.merge!({ 'volume' => ((props['volume'].to_i || 0) + 1).to_s })
            edge.properties = props          
            puts edge.to_json
            puts "[#{message_id}] #{t_from.address} --> #{t_bcc.address} [bcc]"
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
    rescue Exception => e
      puts "Exception parsing email: #{e.message}}"
    end
    count += 1
  end
end

def check_email_addresses(addresses)
  addresses.split(/,\s*/).each do |email| 
    unless email =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i
      puts "are invalid -- #{email}"
    end
  end
end