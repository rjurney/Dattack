require 'lib/graph_client'
require 'lib/email_graph'

describe GraphClient, "#new" do
  it "should store a graph, fetch a graph" do
    graph_client = GraphClient.new ENV['VOLDEMORT_STORE'], ENV['VOLDEMORT_ADDRESS']
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
  it "should parse from json" do
    json = "{\"vertices\": {\"3\": {\"_id\": \"3\",\"_type\": \"vertex\",\"address\": \"static.void.dev@gmail.com\",\"type\": \"email\"},\"1\": {\"_id\": \"1\",\"_type\": \"vertex\",\"address\": \"russell.jurney@gmail.com\",\"type\": \"email\"},\"0\": {\"_id\": \"0\",\"_type\": \"vertex\",\"address\": \"yodorf@yahoo.com\",\"type\": \"email\"},\"6\": {\"_id\": \"6\",\"_type\": \"vertex\",\"address\": \"kate.jurney@gmail.com\",\"type\": \"email\"},\"4\": {\"_id\": \"4\",\"_type\": \"vertex\",\"address\": \"common-user@hadoop.apache.org\",\"type\": \"email\"}},\"edges\": [{\"_id\": \"2\",\"_type\": \"edge\",\"label\": \"sent\",\"out_v\": \"0\",\"in_v\": \"1\",\"volume\": \"1\"},{\"_id\": \"7\",\"_type\": \"edge\",\"label\": \"sent\",\"out_v\": \"6\",\"in_v\": \"0\",\"volume\": \"1\"},{\"_id\": \"5\",\"_type\": \"edge\",\"label\": \"sent\",\"out_v\": \"3\",\"in_v\": \"4\",\"volume\": \"1\"}]}"
    graph3 = EmailGraph.new
    graph3.from_json! json
    (graph3.is_a? EmailGraph).should == true
    graph3.v.count.should > 0
    graph3.e.count.should > 0
  end
end