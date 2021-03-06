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
  require './news.rb'
  require './kawahigashi.rb'

  attr_accessor :client, :texts, :year, :kawahigashi

  # URL = "sample/news_update.html"
  URL = "https://www.ms.u-tokyo.ac.jp/~yasuyuki/news.htm"

  def initialize()
    @client = Twitter::REST::Client.new {|config|
      config.consumer_key = load_key("twitter-consumer-key.txt")
      config.consumer_secret = load_key("twitter-consumer-secret.txt")
      config.access_token = load_key("twitter-access-token.txt")
      config.access_token_secret = load_key("twitter-access-token-secret.txt")
    }
    read_texts()
  end

  def wait()
    sleep(3.0)
  end

  def work()
    read_texts()
    @kawahigashi = Kawahigashi.new(URL)
    if !(@kawahigashi.valid?)
      puts "not valid"
      return
    end
    if @texts.nil? || @year.nil?
      # 何もしない
      @year = Time.now.year
    elsif @year != @kawahigashi.year
      make_tweets()
    else
      delete_tweets()
      make_tweets()
    end
    @texts = @kawahigashi.texts
    write_texts()
  end

  def delete_tweets()
    begin
      tweets = @client.user_timeline("kawahigashinews", count: 100)
      wait()
    rescue
      return
    end
    dif = @texts - @kawahigashi.texts
    dif.each{|txt|
      prefix = txt[0...15]
      tweets.each{|tweet|
        if tweet.text.start_with?(prefix)
          begin
            client.destroy_tweet(tweet.id)
            puts "destroy: #{tweet.text}"
            wait()
          rescue
            # 何もしない
          end
          break
        end
      }
    }
  end

  def make_tweets()
    dif = @kawahigashi.texts - @texts
    dif.reverse.each{|txt|
      client.update(txt)
      puts "update: #{txt}"
      wait()
    }
  end

  def read_texts()
    @year = nil
    @texts = []
    path = File.expand_path("../texts.txt", __FILE__)
    if FileTest.exist?(path)
      open(path) {|input|
        @texts = eval(input.read.to_s)
      }
    end
    path = File.expand_path("../year.txt", __FILE__)
    if FileTest.exist?(path)
      open(path) {|input|
        @year = eval(input.read.to_s)
        @year = @year.to_i
      }
    end
  end

  def write_texts()
    path = File.expand_path("../texts.txt", __FILE__)
    open(path, 'w') {|output|
      output.write(@texts.to_s)
    }
    path = File.expand_path("../year.txt", __FILE__)
    open(path, 'w') {|output|
      output.write(@year.to_i)
    }
  end

end
