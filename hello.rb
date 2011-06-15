require 'rubygems'
require 'sinatra'
require 'erb'
#require 'json'

#require './mailgun'
#Mailgun::init("key-41q2py_zo0op3evcz7")

get '/' do
  puts "Hello, worls!"
  "Hello, world!"
end

post '/email' do
  puts "Incoming Email Post: "
  #params.each {|key, value| puts "Key: #{key} Value: #{value}"}
  true
end
