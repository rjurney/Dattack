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
  def find_or_create_edge(from, to, label, unique_field, unique_value)
    # Does the edge exist?
    edges = from.out_e label
    
    found = false
    edges.each do |edge|
      # If not, create and return it
      if (edge.nil?) || (edge[unique_field] != unique_value)
      # If so, return the existing edge
      else
        return edge
      end
    end
    
    # Create it if no match for the edge label and 
    if ! found
      edge = self.create_edge(nil, from, to, label, {unique_field.to_s => unique_value})
    end
  end
end
