require 'rubygems'
require 'sinatra'
require 'erb'
require 'json'
require 'right_aws'

sqs = RightAws::SqsGen2.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
queue = RightAws::SqsGen2::Queue.new(sqs, 'kontexa_test')
queue.clear() # Dev only!

get '/' do
  " "
end

post '/email' do
  puts "ID is: #{params[:subject]}"
  puts "Incoming Email Post: "
  params.each {|key, value| puts "Key: #{key} Value: #{value}"}
  
  queue.push parse_email params

  "true"
end

def parse_email(email)
  return Hash.new(:received => email['Received'],
                  :message_id => email['Message-Id'],
                  :recipient => email['recipient'],
                  :from => email['from'], 
                  :to => email['to'], 
                  :sender => email['sender'],
                  :subject => email['subject'], 
                  :body => email['stripped-text'],
                  :'stripped-html' => email['stripped-html'],
                  :'body-plain' => email['body-plain'] )
end
