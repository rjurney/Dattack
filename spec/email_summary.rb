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
  
  # it "should parse from json" do
  #   
  # end
end