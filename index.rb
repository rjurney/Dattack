require 'rubygems'
require 'sinatra'
require 'erb'
require 'json'

require './mailgun'
Mailgun::init("key-41q2py_zo0op3evcz7")

post '/email' do
  @params = params
  erb :'index.html.erb'
end