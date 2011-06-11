require 'rubygems'
require 'sinatra'
require 'erb'
require 'json'

require './mailgun'
Mailgun::init("key-41q2py_zo0op3evcz7")

get '/' do
  puts "Hello, worls!"
  @params = 'foo'
  erb :'index.html.erb'
end

post '/email/:data' do |data|
  puts "We got a request, yo!"
  @params = params
  puts @params.inspect
  puts "Data: #{data.inspect}"
end