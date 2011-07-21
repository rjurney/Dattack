def save_state(graph, user_name, client, message_id=nil)
    puts "Saving... #{graph}"
    
    # Graphml
    system "rm /tmp/#{user_name}.graphml"
    graph.export "/tmp/#{user_name}.graphml"
    
    # JSON -> /tmp
    client.write_voldemort_json user_name
    
    # Voldemort as JSON
    client.set user_name, graph
    
    # Save the message_id we are on for resume, unless we're all done!
    if message_id
      client.voldemort.put "resume_id:#{user_name}", message_id.to_s
    else
      client.voldemort.delete "resume_id:#{user_name}"
    end
end