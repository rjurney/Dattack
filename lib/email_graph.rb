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
    
    found_edge = nil
    if edge
      edge.each do |e|
        if e and e.in_v
          e.in_v.each do |inv| 
            if inv.equals? to
              return e
            end
          end
        end
      end
    end
    e = self.create_edge(nil, from, to, label)
  end
  
  # Intersect two graphs using the value of unique_key to compare nodes
  # Assumes unique_key is in fact unique in both graphs.
  def intersect!(g2, unique_key)
    g2.v.each do |v2|
      search = self.v(unique_key => v2[unique_key])
      if search.count > 0
        v1 = search.first
        self.merge v1, v2
      else
        # Nada, no intersection on this node
      end
  end
  
  # Union two graphs using the value of unique_key to compare nodes
  def union!(g2, unique_key)
    
  end
  
  # Merge properties and find_or_create & increment/merge edges
  def merge(v1, v2)
    
  end
end
