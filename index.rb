require 'rubygems'
require 'sinatra'
require 'erb'
require 'json'
require 'right_aws'

require 'lib/mailgun'
Mailgun::init("key-41q2py_zo0op3evcz7")

sqs = RightAws::SqsGen2.new(AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)

get '/' do
  " "
end

post '/email' do
  puts "ID is: #{params[:subject]}"
  puts "Incoming Email Post: "
  params.each {|key, value| puts "Key: #{key} Value: #{value}"}
  
  sqs.put parse_email params

  "true"
end

def parse_email(email)
  return JSON {
                :received => email['Received'],
                :message_id => email['Message-Id'],
                :recipient => email['recipient'],
                :from => email['from'], 
                :to => email['to'], 
                :sender => email['sender'],
                :subject => email['subject'], 
                :body => email['stripped-text'],
                :'stripped-html' => email['stripped-html'],
                :'body-plain' => email['body-plain']
              }
end