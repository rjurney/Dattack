require 'stemmer'

class Email
  attr_accessor :terms, :boost, :stop_words, :body
  
  def initialize
    @stop_words = []
	  file = File.new(File.dirname(__FILE__) + "/english.stop", "r")
	  while (line = file.gets)
      @stop_words << line.chop
    end
    file.close
  end

  def to_terms()
    # remove all non letters and reject stop words
    terms_list = self.gsub(/(\s|\d|\W)+/u,' ').rstrip.strip.downcase.split(' ').reject{|term|$stop_words.include?(term)}
    # transform to a hash with a frequency * boost value
    terms_list.each do|term|
      term = term.stem
      if terms[term]
        terms[term] = terms[term] + boost
      else
        terms[term] = boost
      end
    end
    terms
  end 

  def to_tf_idf
    #assume we have a method that returns the df value for any term
    total_frequency = terms.values.inject(0){|a,b|a+b}
    terms.each do |term,freq| 
      terms[term]= (freq / total_frequency) * self.df(term)
      magnitude = magnitude + terms[term]**2
    end
    return terms, magnitude
  end
  
  def match(item)
    my_tf_idf,  my_magnitude  = self.to_tf_idf
    his_tf_idf, his_magnitude = item.to_tf_idf
    dot_product = 0
    my_tf_idf.each do |term,tf_idf|
      dot_product = dot_product + tf_idf * his_tf_idf[term] if his_tf_idf[term]
    end
    cosine_similarity = dot_product / Math.sqrt(my_magnitude * his_magnitude)
  end
  
  def df(term)
  
  end
end
