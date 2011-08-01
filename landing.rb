# Simple app to publish landing/signup page.  Will merge/fix later, 
# just need to get a web presence up on www.kontexa.com right now.

require 'rubygems'
require 'sinatra'
require 'erb'
require 'redis'
require 'tmail'

require 'jcode'
$KCODE = 'UTF8'

require 'date'
require 'date/format'

redis_uri = URI.parse(ENV["REDISTOGO_URL"])
redis = Redis.new(:host => redis_uri.host, :port => redis_uri.port, :password => redis_uri.password)

set :public, File.dirname(__FILE__) + '/static'

get "/" do
  erb :landing
end

post "/signup" do
  email = params[:email]
  if is_valid email
    redis.set email, "1"
    "Email: #{email}"
  else
    "Invalid Email: #{email}"
  end
end

def is_valid(email)
  begin
    t_email = TMail::Address.parse email
    true
  rescue
    false
  end
end