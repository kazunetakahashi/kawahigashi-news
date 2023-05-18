require 'oauth'
require 'json'
require 'typhoeus'
require 'oauth/request_proxy/typhoeus_request'
require 'dotenv/load'
require './loadkey.rb'
include LoadKey

class TwitterV2
  def self.tweet(text)
    consumer_key = load_key("twitter-consumer-key.txt")
    consumer_secret = load_key("twitter-consumer-secret.txt")
    access_token = load_key("twitter-access-token.txt")
    access_token_secret = load_key("twitter-access-token-secret.txt")

    create_tweet_url = "https://api.twitter.com/2/tweets"

    json_payload = {"text": text}

    def self.create_tweet(url, oauth_params, json_payload)
      options = {
        :method => :post,
        headers: {
          "User-Agent": "v2CreateTweetRuby",
          "content-type": "application/json"
        },
        body: JSON.dump(json_payload)
      }
      request = Typhoeus::Request.new(url, options)
      oauth_helper = OAuth::Client::Helper.new(request, oauth_params.merge(:request_uri => url))
      request.options[:headers].merge!({"Authorization" => oauth_helper.header}) # Signs the request
      response = request.run

      return response
    end

    consumer = OAuth::Consumer.new(consumer_key, consumer_secret,
      :site => 'https://api.twitter.com',
      :debug_output => false)

    access_token = OAuth::AccessToken.new(consumer, access_token, access_token_secret)

    oauth_params = {
      :consumer => consumer,
      :token => access_token,
    }

    response = create_tweet(create_tweet_url, oauth_params, json_payload)
    response
  end
end
