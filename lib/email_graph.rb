require 'pacer'
require 'json'

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
    g2_edges = []
    g2.v.each do |v2|
      search = self.v(unique_key => v2[unique_key])
      if search.count > 0
        v1 = search.first
        g2_edges += self.intersect_vertex! v1, v2
      else
        # Nada, no intersection on this node
      end
    end
    e1 = self.e 'sent'
    g2.e('sent').each do |e2|
      puts e2
      
      type.each do |e|
        self.v(unique_key => e.out_v[unique_key])
      end
    end
  end
  
  # Union two graphs using the value of unique_key to compare nodes
  def union!(g2, unique_key)
    
  end
  
  # Merge node properties and return new edges to merge
  def intersect_vertex!(v1, v2)
    raise Exception.new("v1 must belong to this graph!") unless v1.graph === self 
    
    # Merge proprties, return edge list for additional processing
    props1 = v1.properties
    props2 = v2.properties
        
    # Merge propertie
    v1.properties = intersect props1, props2
    nil
  end
  
  # Merge edges that have the same unique_key values on each vertex end
  def intersect_edge!(e1, e2, unique_key)
    raise Exception.new("e1 must belong to this graph!") unless e1.graph === self
    
    if e1.label === e2.label
      if e1.in_v[unique_key] === e2.in_v[unique_key]
        if e1.out_v[unique_key] === e2.out_v[unique_key]
          
        end
      end
    end
  end
  
  def intersect(hash1, hash2)
    intersection = hash1.keys & hash2.keys
    c = hash1.dup.update(hash2)
    inter = {}
    intersection.each {|k| inter[k]=c[k] }
    inter
  end
end
