consumer_key = ENV["CONSUMER_KEY"] || ENV["consumer_key"]
consumer_secret = ENV["CONSUMER_SECRET"] || ENV["consumer_secret"]

config.omniauth :google_apps, OpenID::Store::Filesystem.new('./tmp'), :domain => 'gmail.com'
config.omniauth :google, consumer_key, consumer_secret, :scope => 'https://mail.google.com/'
