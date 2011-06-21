require 'pacer'

class EmailGraph < Pacer::TinkerGraph

  # If a vertex exists, return it.  Otherwise create it.
  # 
  # Example Usage: cc = find_or_create_vertex {:type => 'email', :address => email}, :type
  #
  def find_or_create_vertex(properties, key)
    if self.v(key =>  properties[key]).empty?
      vertex = self.create_vertex(properties)
    else
      vertex = self.v(key => properties[key]).first
    end
  end
  
  # If an edge exists, increment it.  Otherwise create it and then increment it.
  #
  # Example Usage: graph.find_or_increment_edge nil, from, cc, 'sent', {volume => 1}
  #
  def find_or_increment_edge(from, to, key, amount)
    # Check for an existing edge with a traversal
    summary_graph.create_edge nil, vertices[sender], vertices[recipient], :sent, {:volume => volume}
  end
end
