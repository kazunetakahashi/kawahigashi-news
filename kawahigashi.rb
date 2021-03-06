#
# File    : kawahigashi.rb
# Author  : Kazune Takahashi
# Created : 1/16/2019, 10:54:10 PM
# Powered by Visual Studio Code
#

class Kawahigashi
  require './news.rb'
  require 'open-uri'
  require 'nokogiri'

  attr_accessor :year, :components, :texts

  def initialize(url)
    @year = nil
    @components = nil
    @texts = []
    doc = nil
    begin
      page = URI.parse(url).read
      doc = Nokogiri::HTML(page, url, "EUC-JP")
    rescue
      # 何もしない
    end
    if doc.nil?
      return nil
    end
    x = doc.xpath("/html/body/h1")
    if x && m = x.text.match(/(\d{4})年/)
      @year = m[1].to_i
    end
    if @year.nil?
      return nil
    end
    x = doc.xpath("/html/body/p")
    if x
      @components = []
      x.each{|para|
        n = News.new()
        if n.make_news(para)
          @components << n
        end
      }
    end
    if @components.nil? || @components.empty?
      return nil
    end
    @components.each{|news|
      @texts << news.to_s
    }
  end

  def valid?
    !(@year.nil? || @components.nil? || @components.empty? ||
       @texts.nil? || @texts.empty?)
  end

end
