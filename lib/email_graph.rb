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
  def find_or_create_edge(from, to, label, properties={})
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
    e = self.create_edge(nil, from, to, label, properties)
  end
  
  # Intersect two graphs using the value of unique_key to compare nodes
  # Assumes unique_key is in fact unique in both graphs.
  def intersect!(g2, unique_key)
    nuked = []
    self.v.each do |v1|
      search = g2.v(unique_key => v1[unique_key])
      if search.count > 0
        v2 = search.first
        self.intersect_vertex! v1, v2, unique_key
      else
        nuked << v1
      end
    end
    nuked.each {|v| v.delete!}
  end
  
  # Union two graphs using the value of unique_key to compare nodes
  def union!(g2, unique_key)
    new_nodes = []
    self.v.each do |v1|
      search = g2.v(unique_key => v1[unique_key])
      if search.count > 0
        v2 = search.first
        self.union_vertex! v1, v2, unique_key
      else
        new_v2 = self.find_or_create_vertex v2.properties, v2[unique_key]
        new_nodes << [new_v2, v2.out_e]
      end
    end
    # All nodes at the end of new edges having been created, now create the new edges
    new_nodes.each do |new_v2, out_edges|
    
    end
  end
  
  # Merge node properties and return new edges to merge
  def intersect_vertex!(v1, v2, unique_key)
    raise Exception.new("v1 must belong to this graph!") unless v1.graph === self
        
    # Merge properties
    v1.properties = intersect_hash v1.properties, v2.properties
    
    nukes = []
    # Merge edges
    v1.out_e.each do |e1|
       match = false
       v2.out_e.each do |e2|
          if e1.out_v.first[unique_key] === e2.out_v.first[unique_key]
             if e1.in_v.first[unique_key] === e2.in_v.first[unique_key]
                match = true
                puts "Match on #{e1.out_v.first[unique_key]} <-> #{e1.in_v.first[unique_key]}"
                volume = (e1['volume']||0) + (e2['volume']||0)
          	    e1.properties = intersect_hash e1.properties, e2.properties
          	    e1['volume'] = volume
                break
             end
          end
       end
       
       unless match
          nukes << e1
       end
    end
    
    nukes.each {|e| e.delete!}   
    v1
  end
  
  # Union properties, then return outbound edges
  def union_vertex!(v1, v2, unique_key)
    raise Exception.new("v1 must belong to this graph!") unless v1.graph === self
        
    # Merge properties
    v1.properties = union_hash v1.properties, v2.properties
    
    # Get the pipe to emit all outbound edges now, then return the list
    es = []
    v2.out_e.each do |e|
       es << e
    end
    
    return v1, es
  end
  
  def intersect_hash(hash1, hash2)
    intersection = hash1.keys & hash2.keys
    c = hash1.dup.update(hash2)
    inter = {}
    intersection.each {|k| inter[k]=c[k] }
    inter
  end
  
  def union_hash(hash1, hash2)
    hash1.merge hash2
  end
end
