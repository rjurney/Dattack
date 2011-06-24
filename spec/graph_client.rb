require 'lib/graph_client'
require 'lib/email_graph'

describe GraphClient, "#new" do
  it "should store a graph, fetch a graph" do
    graph_client = GraphClient.new ENV['VOLDEMORT_STORE'], ENV['VOLDEMORT_ADDRESS'], ENV['MEMCACHED_ADDRESS']
    graph = EmailGraph.new
  
    properties1 = {:type => 'email', :address => 'russell.jurney@gmail.com'}
    properties2 = {:type => 'email', :address => 'kate.jurney@gmail.com'}
  
    from = graph.create_vertex properties1
    to = graph.create_vertex properties2
    edge1 = graph.create_edge(nil, from, to, :sent, {})

    graph_client.delete 'unit_test'
    graph_client.set 'unit_test', graph
    graph2 = graph_client.get 'unit_test'
    graph2.v.count.should == graph.v.count
    graph_client.delete 'unit_test'
  end
end