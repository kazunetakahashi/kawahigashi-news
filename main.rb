#
# File    : main.rb
# Author  : Kazune Takahashi
# Created : 1/18/2019, 8:38:11 AM
# Powered by Visual Studio Code
#

require './bot.rb'
require 'clockwork'
require 'active_support/all'
include Clockwork

@bot = Bot.new()

every(1.minutes, 'work') {
  @bot.work()
}