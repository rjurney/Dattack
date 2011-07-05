def save_state(graph, user, client)
    puts "Saving... #{graph}"
    system "rm /tmp/#{user}.graphml"
    graph.export "/tmp/#{user}.graphml"
    client.set user, graph
end