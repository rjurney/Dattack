require 'rubygems'
require 'sinatra'
require 'erb'
require 'json'

require 'lib/mailgun'
Mailgun::init("key-41q2py_zo0op3evcz7")

get '/' do
  ""
end

post '/email' do
  puts "ID is: #{params[:subject]}"
  puts "Incoming Email Post: "
  params.each {|key, value| puts "Key: #{key} Value: #{value}"}
  "true"
end
