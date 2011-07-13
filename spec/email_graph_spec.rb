require 'lib/email_graph'
require 'rspec'

describe EmailGraph, "#find_or_create_vertex" do
  # Setup
  graph = EmailGraph.new
  properties1 = {:type => 'email', :address => 'russell.jurney@gmail.com'}
  properties2 = {:type => 'email', :address => 'kate.jurney@gmail.com'}
  
  vertex1 = nil
  it "creates a new vertex if none is found to match its index field" do
    vertex1 = graph.find_or_create_vertex properties1, :address
    vertex1[:type].should == 'email'
    vertex1[:address].should == 'russell.jurney@gmail.com'
    graph.v(:address => 'russell.jurney@gmail.com').first.should === vertex1
  end
  
  it "returns the existing vertex if one is found that matches its index field" do
    # Get the existing vertex
    vertex2 = graph.find_or_create_vertex properties1, :address
    vertex2.should === vertex1
  end
end

describe EmailGraph, "#find_or_create_edge" do
  # Setup
  graph = EmailGraph.new
  properties1 = {:type => 'email', :address => 'russell.jurney@gmail.com'}
  properties2 = {:type => 'email', :address => 'kate.jurney@gmail.com'}
  properties3 = {:type => 'email', :address => 'jurney@gmail.com'}
  
  from = graph.create_vertex properties1
  to = graph.create_vertex properties2
  other = graph.create_vertex properties3
  edge1 = nil
  edge2 = nil
  edge3 = nil
  
  it "should create a new edge when none is present" do
    edge1 = graph.find_or_create_edge(from, to, 'sent')
    edge1.out_v.first.should === from
    edge1.in_v.first.should === to
  end
  
  it "different edge labels should not duplicate the previously created edge" do
    edge2 = graph.find_or_create_edge(from, to, 'received')
    edge2.should_not === edge1
  end
  
  it "should return an existing edge" do
    edge3 = graph.find_or_create_edge(from, to, 'sent')
    puts edge3.to_json
    puts edge1.to_json
    (edge3.eql? edge1).should == true
    edge3.should_not == edge2
  end
end

describe EmailGraph, "#intersect" do
  # Original graph
  graph1 = EmailGraph.new

  node1 = graph1.create_vertex({:type => 'email', :address => 'russell.jurney@gmail.com', :network => 'foo@bar.com'})
  node2 = graph1.create_vertex({:type => 'email', :address => 'kate.jurney@gmail.com'})
  node3 = graph1.create_vertex({:type => 'email', :address => 'jurney@gmail.com'})
  edge1 = graph1.find_or_create_edge(node1, node2, 'sent')
  edge2 = graph1.find_or_create_edge(node1, node3, 'sent')
  edge3 = graph1.find_or_create_edge(node2, node1, 'sent')
  
  # Graph to interset
  graph2 = EmailGraph.new
  v1 = graph2.create_vertex({:type => 'email', :address => 'russell.jurney@gmail.com'})
  v2 = graph2.create_vertex({:type => 'email', :address => 'kate.jurney@gmail.com'})
  v3 = graph2.create_vertex({:type => 'email', :address => 'billy@go.com'})
  e1 = graph2.find_or_create_edge(v1, v2, 'sent')
  e2 = graph2.find_or_create_edge(v1, v3, 'sent')
  e3 = graph2.find_or_create_edge(v2, v3, 'sent')
  
  # Graphs are ready - now intersect them and inspect the result.
  #node1.out_e.count.should == 2
  graph1.intersect_vertex! node1, v1, 'address'
  node1.both_e.count.should == 1
  
  node1.properties.size.should == 2
  node1['type'].should == 'email'
  node1['address'].should == 'russell.jurney@gmail.com' 
  
end
