require 'rubygems'
require 'sinatra'
require 'erb'
require 'json'
require 'right_aws'
require 'redis'
require 'uuid'
require 'uri'
require "oauth"
require "oauth/consumer"
require 'haml'
require 'jcode'
$KCODE = 'UTF8'
require 'date'
require 'date/format'

enable :sessions

before do
  session[:oauth] ||= {}
  
  consumer_key = ENV["CONSUMER_KEY"] || ENV["consumer_key"]
  consumer_secret = ENV["CONSUMER_SECRET"] || ENV["consumer_secret"]
  
  @consumer ||= OAuth::Consumer.new(consumer_key, consumer_secret,
    :site => "https://www.google.com",
    :request_token_path => '/accounts/OAuthGetRequestToken?scope=https://mail.google.com/%20https://www.googleapis.com/auth/userinfo%23email',
	  :access_token_path => '/accounts/OAuthGetAccessToken',
	  :authorize_path => '/accounts/OAuthAuthorizeToken'
  )
  
  if !session[:oauth][:request_token].nil? && !session[:oauth][:request_token_secret].nil?
	  @request_token = OAuth::RequestToken.new(@consumer, session[:oauth][:request_token], session[:oauth][:request_token_secret])
  end
  
  if !session[:oauth][:access_token].nil? && !session[:oauth][:access_token_secret].nil?
	  @access_token = OAuth::AccessToken.new(@consumer, session[:oauth][:access_token], session[:oauth][:access_token_secret])
  end
end

get "/" do
  #   if @access_token
  #   erb :index
  # else
	  erb :login
  # end
end

get "/request" do
  @request_token = @consumer.get_request_token(:oauth_callback => "#{request.scheme}://#{request.host}:#{request.port}/auth")
  session[:oauth][:request_token] = @request_token.token
  session[:oauth][:request_token_secret] = @request_token.secret
  redirect @request_token.authorize_url
end

get "/auth" do
  @access_token = @request_token.get_access_token :oauth_verifier => params[:oauth_verifier]
  session[:oauth][:access_token] = @access_token.token
  session[:oauth][:access_token_secret] = @access_token.secret

  #get_set_email @access_token

  redirect "/"
end

get "/logout" do
  session[:oauth] = {}
  redirect "/"
end

def get_set_email(access_token)
  response = access_token.get('https://www.googleapis.com/userinfo/email?alt=json')
  if response.is_a?(Net::HTTPSuccess)
    email = JSON.parse(response.body)['data']['email']
    json_token = JSON({ :token => access_token.token, :secret => access_token.secret, :email => email, :date => DateTime.now.to_s })
    @redis.set 'access_token:' + email, json_token
    return email
  else
    STDERR.puts "could not get email: #{response.inspect}"
    return nil
  end
end

# @sqs = RightAws::SqsGen2.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
# @queue = RightAws::SqsGen2::Queue.new(@sqs, 'kontexa_test')
# @queue.clear() # Dev only!
# 
# post '/email' do
#   @uuid_factory = UUID.new
#   uuid = @uuid_factory.generate
#   puts "UUID: #{uuid}"
#   json = JSON.generate(params)
# 
#   @redis.set(uuid, json)
#   ['From', 'To', 'Cc', 'sender', 'subject', 'body-plain'].each do |key|
#     puts "###{key}##  #{params[key]}"
#   end
#   
#   # Need to put the identity of the user of the service here, reliably, somehow, appended to the uuid?
#   @queue.push uuid
#   "true"
# end
