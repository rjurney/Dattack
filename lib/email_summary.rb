require 'stemmer' # This gives us String.stem
require 'voldemort-rb'

PREFIX = "summary:"

class EmailSummary
  attr_accessor :terms, :boost, :stop_words, :body, :subject, :voldemort
  
  def initialize(subject, body)
    raise VoldemortException, "Must set ENV['VOLDEMORT_STORE'] and ENV['VOLDEMORT_ADDRESS']" \
      unless(ENV['VOLDEMORT_STORE'] && ENV['VOLDEMORT_ADDRESS'])
    @subject = subject
    @body = body
    self.load_stop_words
    self.load_dict
    @voldemort = VoldemortClient.new ENV['VOLDEMORT_STORE'], ENV['VOLDEMORT_ADDRESS']
  end
  
  def load_stop_words
    @stop_words = []
    file = File.new("data/english.stop", "r")
    while(line = file.gets)
      @stop_words << line.chop
    end
    file.close
  end
  
  def load_dict
    @dict = []
    file = File.new("/usr/share/dict/words", "r")
    while(line = file.gets)
      @dict << line.chop
    end
  end
  
  def summarize
    self.to_terms
    tfs, magnitude = self.to_tf_idf
    puts tfs.inspect
    puts magnitude
  end

  def to_terms(terms={}, boost=1)
    # remove all non letters and reject stop words
    terms_list = @body.gsub(/(\s|\d|\W)+/u,' ').rstrip.strip.downcase.split(' ').reject{|term|@stop_words.include?(term)}

    # transform to a hash with a frequency * boost value
    terms_list.each do |term|
      # If its in the dictionary, stem it.  Otherwise leave it be, presumably its a technical term/jargon.
      if @dict.include?(term)
        term = term.stem if term.stem
      end
      if terms[term]
        terms[term] = terms[term] + boost.to_f
      else
        terms[term] = boost.to_f
      end
    end
    @terms = terms
  end 

  def to_tf_idf
    tfs = {}
    magnitude = 0
    total_frequency = @terms.values.inject(0){|a,b|a+b}
    puts "\nTotal frequency: #{total_frequency}"
    @terms.each do |term,freq|
      puts "Term: #{term}, Freq: #{freq}"
      tfs[term]= (freq / total_frequency) * (self.df(term) || 1)
      puts tfs[term]
      magnitude = magnitude + tfs[term]**2
    end
    return tfs, magnitude
  end

  #assume we have a method that returns the df value for any term
  def df(term)
    1.0
    #@voldemort.get(PREFIX + term) || 1
  end
  
  # def match(item)
  #   my_tf_idf,  my_magnitude  = self.to_tf_idf
  #   his_tf_idf, his_magnitude = item.to_tf_idf
  #   dot_product = 0
  #   my_tf_idf.each do |term,tf_idf|
  #     dot_product = dot_product + tf_idf * his_tf_idf[term] if his_tf_idf[term]
  #   end
  #   cosine_similarity = dot_product / Math.sqrt(my_magnitude * his_magnitude)
  # end
end

class VoldemortException < Exception
  attr :voldemort_error_string
  
  def initialize(error_message)
    @voldemort_error_string = error_message
    self.debug_message
  end
  
  def debug_message
    puts "Error string: #{@voldemort_error_string}"
    puts self.message
    puts self.backtrace
    exit
  end
end
