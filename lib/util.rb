def save_state(graph, user, client)
    puts "Saving... #{graph}"
    
    # Graphml
    system "rm /tmp/#{user}.graphml"
    graph.export "/tmp/#{user}.graphml"
    
    # JSON -> /tmp
    client.write_voldemort_json user
    
    # Voldemort as JSON
    client.set user, graph
end