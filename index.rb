require 'rubygems'
require 'sinatra'
require 'erb'
require 'json'

require './mailgun'
Mailgun::init("key-41q2py_zo0op3evcz7")

post '/email/:data' do |data|
  @params = params
  puts @params.inspect
  puts "Data: #{data.inspect}"
  erb :'index.html.erb'
end