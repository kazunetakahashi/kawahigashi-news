#
# File    : misc.rb
# Author  : Kazune Takahashi
# Created : 5/1/2021, 2:52:12 PM
# Powered by Visual Studio Code
#

class Misc
  require './news.rb'
  require 'open-uri'
  require 'nokogiri'

  attr_accessor :components, :texts

  def initialize(url)
    @components = nil
    @texts = []
    doc = nil
    begin
      page = URI.parse(url).read
      # page = File.read(url)
      doc = Nokogiri::HTML(page, url, "EUC-JP")
    rescue
      # 何もしない
    end
    if doc.nil?
      return nil
    end
    x = doc.xpath("/html/body/ul/li")
    if x
      @components = []
      x.each{|para|
        n = News.new()
        if n.make_news(para, :misc)
          @components << n
        end
      }
    end
    if @components.nil? || @components.empty?
      return nil
    end
    @components.reverse!
    @components.each{|news|
      @texts << news.to_s
    }
  end

  def valid?
    !(@components.nil? || @components.empty? ||
       @texts.nil? || @texts.empty?)
  end

end
