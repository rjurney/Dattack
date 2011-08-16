module EmailMixin
  def count_recipients
    for to in ['to', 'cc', 'bcc']
      if mail.header[to] and mail.header[to].respond_to? 'addrs'
        to_addresses = mail.header[to].addrs
        recipient_count += to_addresses.size
      end
    end
  end

  def new_imap
    imap.close if imap and imap.respond_to? 'close'
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
	  imap
	end
	
	def build_connections types
	  for type in types
	    if mail.header[type] and mail.header[type].respond_to? 'addrs'
        to_addresses = mail.header[type].addrs
        to_addresses.each do |t_to|
          to_address = t_to.address.downcase.gsub /"/, '' #"
          to = graph.find_or_create_vertex({:type => 'email', :address => to_address, :network => USERNAME}, :address)
          edge, status = graph.find_or_create_edge(from, to, 'sent')
          props = edge.properties || {}
          # Ugly as all hell, but JSON won't let you have a numeric key in an object...
          props.merge!({ 'Weight' => ((props['Weight'].to_i || 0) + 1.0/(recipient_count||1.0)).to_s })
          edge.properties = props
          puts "[#{message_id}] #{from_address} --> #{to_address} [#{type}] #{props['Weight']}"
        end
      end
    end
	end
	
	def process_args
	  unless(ARGV[0])
 	    puts "Must supply gmail username as 1st argument, or set ENV['GMAIL_USERNAME']"
  	  exit
	  end

	  unless(ENV['VOLDEMORT_STORE'] && ENV['VOLDEMORT_ADDRESS'])
  	  puts "Must set ENV['VOLDEMORT_STORE'] and ENV['VOLDEMORT_ADDRESS']"
  	  exit
	  end
	end
	
	def save_state
    puts "Saving... #{graph}"
    
    # Graphml
    system "rm /tmp/#{USERKEY}.graphml"
    graph.export "/tmp/#{USERKEY}.graphml"
    
    # JSON -> /tmp
    graph_client.write_voldemort_json USERKEY
    
    # Voldemort as JSON
    graph_client.set USERKEY, graph
    
    # Save the message_id we are on for resume, unless we're all done
    graph_client.voldemort.put "resume_id:#{USERKEY}", message_id.to_s
  end
end