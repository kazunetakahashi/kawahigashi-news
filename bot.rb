#
# File    : bot.rb
# Author  : Kazune Takahashi
# Created : 1/17/2019, 9:41:55 PM
# Powered by Visual Studio Code
#

class Bot
  require 'twitter'
  require './loadkey.rb'
  include LoadKey
  load './news.rb'
  load './kawahigashi.rb'

  attr_accessor :client, :texts, :kawahigashi

  URL = "http://www.ms.u-tokyo.ac.jp/~yasuyuki/news.htm"
  # URL = "http://www.ms.u-tokyo.ac.jp/~yasuyuki/news.htm"

  def initialize()
    @client = Twitter::REST::Client.new {|config|
      config.consumer_key = load_key("twitter-consumer-key.txt")
      config.consumer_secret = load_key("twitter-consumer-secret.txt")
      config.access_token = load_key("twitter-access-token.txt")
      config.access_token_secret = load_key("twitter-access-token-secret.txt")
    }
    read_texts()
  end

  def work()
    read_texts()
    @kawahigashi = Kawahigashi.new(URL)
    delete_tweets()
    make_tweets()
    @texts = @kawahigashi.texts
    write_texts()
  end

  def delete_tweets()
    tweets = @client.user_timeline("kawahigashinews", count: 100)
  end

  def make_tweets()
  end

  def read_texts()
    @texts = []
    path = File.expand_path("../texts.txt", __FILE__)
    if FileTest.exist?(path)
      open(path) {|input|
        @texts = eval(input.read.to_s)
      }
    end
  end

  def write_texts()
    path = File.expand_path("../texts.txt", __FILE__)
    open(path, 'w') {|output|
      output.write(@texts.to_s)
    }
  end


end