require 'pacer'

class EmailGraph < Pacer::TinkerGraph

  # If a vertex exists, return it.  Otherwise create it.
  # 
  # Example Usage: cc = find_or_create_vertex {:type => 'email', :address => email}, :type
  #
  def find_or_create_vertex(properties, key)
    if self.v(key => properties[key]).empty?
      vertex = self.create_vertex(properties)
    else
      vertex = self.v(key => properties[key]).first
    end
  end
  
  # If an edge exists, increment it.  Otherwise create it and then increment it.
  #
  # Example Usage: graph.find_or_create_edge from, cc, :sent
  #
  def find_or_create_edge(from, to, label)
    # Does the edge exist?
    edge = from.out_e label
    edge &&= edge.first
    
    if edge.nil?
      edge = self.create_edge(nil, from, to, label)
    else
      return edge
    end
  end
end
