# Simple app to publish landing/signup page.  Will merge/fix later, 
# just need to get a web presence up on www.kontexa.com right now.

require 'rubygems'
require 'sinatra/base'
require 'erb'
require 'json'
require 'redis'
require 'tmail'
require 'uri'
require 'oauth'
require 'oauth/consumer'
require 'lib/graph_client'
require 'lib/email_graph'

require 'jcode'
$KCODE = 'UTF8'

require 'date'
require 'date/format'
module Kontexa
  class Kontexa::HomePage < Sinatra::Base

    # Sinatra setup
    set :static, true
    set :show_exceptions, false
    set :public, File.dirname(__FILE__) + '/static'
    set :views, File.dirname(__FILE__) + '/views'
    set :sessions, true

    # Object persistence setup
    redis_uri = URI.parse(ENV["REDISTOGO_URL"])
    redis = Redis.new(:host => redis_uri.host, :port => redis_uri.port, :password => redis_uri.password)

    # Execute before each call in Sinatra
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
        STDERR.puts "Setting request token"
      end
  
      if !session[:oauth][:access_token].nil? && !session[:oauth][:access_token_secret].nil?
    	  @access_token = OAuth::AccessToken.new(@consumer, session[:oauth][:access_token], session[:oauth][:access_token_secret])
        STDERR.puts "Setting access token"
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
        STDERR.puts "Thanks page!"
        erb :authed
      else
        STDERR.puts "Landing page!"
        erb :landing
      end
    end

    post "/signup" do
      email = params[:email]
      if is_valid? email
        @request_token = @consumer.get_request_token(:oauth_callback => "#{request.scheme}://#{request.host}:#{request.port}/auth")
        puts "Request token: #{@request_token.token} #{@request_token.secret}"
        session[:oauth][:request_token] = @request_token.token
        session[:oauth][:request_token_secret] = @request_token.secret
        session[:oauth][:email] = email
        redirect @request_token.authorize_url
      else
        redirect "/" #"Invalid Email: #{email}"
      end
    end

    get "/auth" do
      unless @request_token
        STDERR.puts "Did not have request_token.  Redirecting to /"
        redirect "/"
        return
      end
      @access_token = @request_token.get_access_token :oauth_verifier => params[:oauth_verifier]
      session[:oauth][:access_token] = @access_token.token
      session[:oauth][:access_token_secret] = @access_token.secret
      STDERR.puts "Fetched new access token from request token"
      @email = session[:oauth][:email]

      json_token = JSON({ :token => @access_token.token, :secret => @access_token.secret, :email => @email, :date => DateTime.now.to_s })
      redis.set "access_token:#{@email}", json_token
  
      redirect "/"
    end

    get "/logout" do
      @access_token = nil
      @request_token = nil
      session[:oauth] = {}
      redirect "/"
    end
    
    get "/demo" do
      redirect "/demo/index.html"
    end
    
    get "/graph/:k" do |k|
      @k = k
      erb :graph
    end
    
    get "/graph.json/:k" do |k|
      k = k.to_f
      content_type :json
      @graph_client = GraphClient.new ENV['VOLDEMORT_STORE'], ENV['VOLDEMORT_ADDRESS']
      graph = @graph_client.get 'imap:russell.jurney@gmail.com'
      graph.wk_core! k
      graph_json = graph.to_json

      # Translate to the expected D3 forced directed format
      etl_graph = JSON graph_json
      new_graph = {}
      
      # Sort nodes, map their ids to an array, make a mapping of those changes, and etl to the new node format
      sorted_nodes = etl_graph['vertices'].values.sort {|x,y| x['_id'].to_i <=> y['_id'].to_i }
      node_map = {}
      sorted_nodes = sorted_nodes.each_index {|i| node_map[sorted_nodes[i]['_id'].to_s] = i; sorted_nodes[i]['_id'] = i}
      etl_nodes = []
      sorted_nodes.each {|node| etl_nodes << {:name => node['Label'], :group => node['network']} }
      new_graph['nodes'] = etl_nodes
      
      # Apply node mapping to edges, and etl them to expected format
      mapped_links = []
      etl_graph['edges'].each do |edge|
        foo = {:source => node_map[edge[1]['out_v']], 
                         :target => node_map[edge[1]['in_v']],
                         :value => edge[1]['Weight'].to_i}
        mapped_links << foo
      end
      new_graph['links'] = mapped_links
      
      # Now return the ETL'd graph that D3 force layout expects
      new_graph.to_json
    end

    def is_valid?(email)
      begin
        t_email = TMail::Address.parse email
        true
      rescue
        false
      end
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

end