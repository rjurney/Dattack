require 'lib/email_summary'

describe EmailSummary, "#new" do
  it "should store a graph, fetch a graph" do
    subject = 'Monitoring'
    body = "Greetings,

    I am relatively new to Hadoop but we now have an 10 node cluster up and running just DFS for now and will be expanding this rapidly as well as adding Hbase. I am looking to find out what people are using for monitoring Hadoop currently. I want to be notified if a node fails, performance statistics, failed drive or services ect. I was thinking of using Opsview and trying in Ganglia. Thanks in advance

    Joe"
    summarizer = EmailSummary.new subject, body
    summarizer.class.should == EmailSummary
  end
end

describe EmailSummary, "#to_terms" do
  it "should produce a list of stems" do
    subject = 'Monitoring'
    body = "Greetings,

    I am relatively new to Hadoop but we now have an 10 node cluster up and running just DFS for now and will be expanding this rapidly as well as adding Hbase. I am looking to find out what people are using for monitoring Hadoop currently. 
    I want to be notified if a node fails, performance statistics, failed drive or services ect. I was thinking of using Opsview and trying in Ganglia. Thanks in advance

    Joe"
    
    summarizer = EmailSummary.new subject, body
    summarizer.to_terms
    summarizer.terms.each_pair {|term, count| STDERR.write "#{term}: #{count.to_s}, " }
    puts ""

    # Two common words that don't get stemmed
    summarizer.terms['monitoring'].should === 1
    summarizer.terms['services'].should === 1
    # Two jargon words that shouldn't get stemmed
    summarizer.terms['hadoop'].should === 2
    summarizer.terms['dfs'].should === 1
    # Two common words that do get stemmed
    summarizer.terms['advanc'].should === 1
    summarizer.terms['notifi'].should === 1
    # Two stop words that should not get through
    summarizer.terms['the'].should === nil
    summarizer.terms['and'].should === nil
  end
end

describe EmailSummary, "#to_tf_idf" do
  it "should do tf_idf" do
    subject = 'Monitoring'
    body = "Greetings,

    I am relatively new to Hadoop but we now have an 10 node cluster up and running just DFS for now and will be expanding this rapidly as well as adding Hbase. I am looking to find out what people are using for monitoring Hadoop currently. 
    I want to be notified if a node fails, performance statistics, failed drive or services ect. I was thinking of using Opsview and trying in Ganglia. Thanks in advance

    Joe"
    
    summarizer = EmailSummary.new subject, body
    summarizer.summarize
    
  end
end