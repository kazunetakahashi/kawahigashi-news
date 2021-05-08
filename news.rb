#
# File    : news.rb
# Author  : Kazune Takahashi
# Created : 1/16/2019, 10:51:12 PM
# Powered by Visual Studio Code
#

class News
  require 'addressable/uri'
  require 'twitter-text'

  attr_accessor :date, :text, :urls

  def initialize()
    @urls = []
  end

  def make_news(para, type)
    str = para.text
    if type == :news
      if str[0] == "・"
        str = str[1...-1]
      else
        return nil
      end
    end
    str = str.gsub(/[\r\n]/, "").strip
    date_reg_exp = /\((\d{1,2})\/(\d{1,2})\/(\d{4})\)$/
    @date = nil
    if m = str.match(date_reg_exp)
      @date = Time.local(m[3].to_i, m[1].to_i, m[2].to_i)
      # p @date
    end
    str = str.gsub(date_reg_exp, "").strip
    @text = str
    if type == :misc
      @text = "『" + @text + "』"
    end
    @text.gsub!(/\*/, "＊")
    # p @text
    @urls = []
    para.css('a').each{|link|
      if link.attributes['href'] && link.attributes['href'].value
        @urls << link.attributes['href'].value
      end
    }
    @urls.map!{|url|
      News.parse_url(url)
    }
    # p @urls
    return true
  end

  def News.parse_url(str)
    # https://oku.edu.mie-u.ac.jp/~okumura/javascript/encodeURI.html を参考にした。
    # https://github.com/sporkmonger/addressable を使用する。
    uri = Addressable::URI.parse(str.to_s)
    ans = uri.normalize.to_s
    ans.gsub!(/\(/, "%28")
    ans.gsub!(/\)/, "%29")
    ans.gsub!(/'/, "%27")
    ans.gsub!(/@/, "%40")
    ans.gsub!(/\.$/, "%2E")
    ans.gsub!(/\*$/, "%2A")
    if !uri.scheme
      ans = "https://www.ms.u-tokyo.ac.jp/~yasuyuki/" + ans
    end
    return ans
  end

  def make_str(t)
    ans = ""
    if @date
      ans += @date.strftime("%m/%d: ")
    end
    ans += @text[0...t]
    if t < @text.size
      ans += "…"
    end
    urls_size = [@urls.size, 4].min
    for i in 0...urls_size
      ans += " " + @urls[i]
    end
    return ans
  end

  def to_s()
    if !(@text) || @text == ""
      return ""
    end
    ub = @text.size + 1
    lb = 0
    while ub - lb > 1
      t = (ub + lb) / 2
      ans = make_str(t)
      if Twitter::TwitterText::Validation.parse_tweet(ans)[:valid]
        lb = t
      else
        ub = t
      end
    end
    return make_str(lb)
  end

end
