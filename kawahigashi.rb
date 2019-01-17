#
# File    : kawahigashi.rb
# Author  : Kazune Takahashi
# Created : 1/16/2019, 10:54:10 PM
# Powered by Visual Studio Code
#

class Kawahigashi
  load './news.rb'
  require 'open-uri'
  require 'nokogiri'

  attr_accessor :year, :components, :texts

  def initialize(url)
    doc = nil
    begin
      doc = Nokogiri::HTML(open(url, 'r',
        :external_encoding => 'EUC-JP', :internal_encoding => 'UTF-8'))
    rescue
      # 何もしない
    end
    if doc.nil?
      return nil
    end
    @year = nil
    x = doc.xpath("/html/body/h1")
    if x && m = x.text.match(/(\d{4})年/)
      @year = m[1].to_i
    end
    if @year.nil?
      return nil
    end
    @components = nil
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
    @texts = []
    @components.each{|news|
      @texts << news.to_s
    }
    return true
  end

end