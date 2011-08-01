# Simple app to publish landing/signup page.  Will merge/fix later, 
# just need to get a web presence up on www.kontexa.com right now.

require 'rubygems'
require 'sinatra'
require 'erb'
require 'json'
require 'redis'
require 'tmail'
require 'uri'
require 'oauth'
require 'oauth/consumer'

require 'jcode'
$KCODE = 'UTF8'

require 'date'
require 'date/format'

redis_uri = URI.parse(ENV["REDISTOGO_URL"])
redis = Redis.new(:host => redis_uri.host, :port => redis_uri.port, :password => redis_uri.password)

set :public, File.dirname(__FILE__) + '/static'
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
  if @access_token
    response = @access_token.get('https://www.googleapis.com/userinfo/email?alt=json')
    if response.is_a?(Net::HTTPSuccess)
      @email = JSON.parse(response.body)['data']['email']
    else
      STDERR.puts "could not get email: #{response.inspect}"
    end
    erb :authed
  else
    erb :landing
  end
end

post "/signup" do
  email = params[:email]
  if is_valid? email
    @request_token = @consumer.get_request_token(:oauth_callback => "#{request.scheme}://#{request.host}:#{request.port}/auth")
    session[:oauth][:request_token] = @request_token.token
    session[:oauth][:request_token_secret] = @request_token.secret
    redirect @request_token.authorize_url
  else
    redirect "/" #"Invalid Email: #{email}"
  end
end

get "/auth" do
  @access_token = @request_token.get_access_token :oauth_verifier => params[:oauth_verifier]
  session[:oauth][:access_token] = @access_token.token
  session[:oauth][:access_token_secret] = @access_token.secret

  response = @access_token.get('https://www.googleapis.com/userinfo/email?alt=json')
  if response.is_a?(Net::HTTPSuccess)
    @email = JSON.parse(response.body)['data']['email']
  else
    STDERR.puts "could not get email: #{response.inspect}"
  end

  json_token = JSON({ :token => @access_token.token, :secret => @access_token.secret, :email => @email, :date => DateTime.now.to_s })
  redis.set "access_token:#{@email}", json_token
  
  redirect "/"
end

get "/logout" do
  session[:oauth] = {}
  redirect "/"
end

def is_valid?(email)
  begin
    t_email = TMail::Address.parse email
    true
  rescue
    false
  end
end