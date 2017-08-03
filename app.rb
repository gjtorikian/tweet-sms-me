configure :development do
  Bundler.require :development
  Envyable.load("config/env.yml", "development")
end

use Rack::TwilioWebhookAuthentication, ENV["TWILIO_AUTH_TOKEN"], "/messages"

post "/messages" do
  twitter.update(params["Body"]) if params["From"] == ENV["MY_PHONE_NUMBER"]
  content_type "text/xml"
  "<Response/>"
end

get "/health" do
  200
end

def twilio
  @twilio ||= Twilio::REST::Client.new(ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"])
end

def twitter
  @twitter ||= Twitter::REST::Client.new do |config|
    config.consumer_key        = ENV["TWITTER_CONSUMER_KEY"]
    config.consumer_secret     = ENV["TWITTER_CONSUMER_SECRET"]
    config.access_token        = ENV["TWITTER_ACCESS_TOKEN"]
    config.access_token_secret = ENV["TWITTER_ACCESS_SECRET"]
  end
end

def send_sms(message)
  twilio.messages.create(
    to: ENV["MY_PHONE_NUMBER"],
    from: ENV["MY_TWILIO_NUMBER"],
    body: message
  )
end

EM.schedule do
  TweetStream.configure do |config|
    config.consumer_key        = ENV["TWITTER_CONSUMER_KEY"]
    config.consumer_secret     = ENV["TWITTER_CONSUMER_SECRET"]
    config.oauth_token         = ENV["TWITTER_ACCESS_TOKEN"]
    config.oauth_token_secret  = ENV["TWITTER_ACCESS_SECRET"]
  end

  client = TweetStream::Client.new

  client.follow([202668848]) do |tweet|
    send_sms("#{tweet.text}\n#{tweet.url}")
  end

  client.userstream
end
