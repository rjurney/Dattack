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
  # Example Usage: graph.find_or_increment_edge from, cc, :sent, {volume => 1}
  #
  def find_or_increment_edge(from, to, type, key, amount)
    # Does the edge exist?
    edge = from.out_e type
    edge &&= edge.first
    
    if edge.nil?
      self.create_edge nil, from, to, type, {key.to_s => amount}
    # If so, increment the field
    else
      edge[key.to_s] += amount
      edge
    end
  end
end
