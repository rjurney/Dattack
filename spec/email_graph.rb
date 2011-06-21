require 'lib/email_graph'

# Setup
graph = EmailGraph.new
properties1 = {:type => 'email', :address => 'russell.jurney@gmail.com'}
properties2 = {:type => 'email', :address => 'kate.jurney@gmail.com'}

describe EmailGraph, "#find_or_create_vertex" do
  vertex1 = nil
  it "creates a new vertex if none is found to match its index field" do
    # Create a vertex
    vertex1 = graph.find_or_create_vertex properties1, :type
    vertex1[:type].should == 'email'
    vertex1[:address].should == 'russell.jurney@gmail.com'
    graph.v(:address => 'russell.jurney@gmail.com').first.should === vertex1
  end
  
  it "returns the existing vertex if one is found that matches its index field" do
    # Get the existing vertex
    vertex2 = graph.find_or_create_vertex properties2, :type
    vertex2.should === vertex1
  end
end