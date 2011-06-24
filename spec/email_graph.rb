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

describe EmailGraph, "#find_or_increment_edge" do
  # Setup
  graph = EmailGraph.new
  properties1 = {:type => 'email', :address => 'russell.jurney@gmail.com'}
  properties2 = {:type => 'email', :address => 'kate.jurney@gmail.com'}
  
  from = graph.create_vertex properties1
  to = graph.create_vertex properties2
  edge1 = nil
  
  it "should create a new edge when none is present" do
    edge1 = graph.find_or_increment_edge(from, to, 'sent', 'volume', 1)
    edge1.out_v.first.should === from
    edge1.in_v.first.should === to
    edge1['volume'].should === 1
  end
  
  it "should increment the value of the key in an existing edge" do
    edge2 = graph.find_or_increment_edge(from, to, 'sent', 'volume', 4)
    edge2['volume'].should === 5
    edge2.should === edge1
  end
end