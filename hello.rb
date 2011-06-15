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

get '/foo' do
 @params = 'foo'
 erb :index
end

post '/email' do
  puts "We got a POST, yo!"
  @params = params
  puts @params.inspect
  #puts "Data: #{data.inspect}"
  true
end

get '/email' do
  puts "We got a GET, yo!"
  @params = params
  puts @params.inspect
  #puts "Data: #{data.inspect}"
  true
end