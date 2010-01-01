# -*- coding: utf-8 -*-
=begin
###############################################################################
#
# Copyright (c) 2009 by Dominik Honnef <dominikho@gmx.net>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#
###############################################################################
# History:
#   2010-01-01, Dominik Honnef <dominikho@gmx.net>:
#       v0.0.3: properly colorize prefices, too
#   2009-12-24, Dominik Honnef <dominikho@gmx.net>:
#       v0.0.2: white- and blacklists now work per server
#   2009-12-24, Dominik Honnef <dominikho@gmx.net>:
#       version 0.0.1
#
###############################################################################
=end

require 'weechat'
include Weechat
include Script::Skeleton
include Weechat::Helper

@script = {
  :name        => "colorize_nicks",
  :author      => "Dominik Honnef <dominikho@gmx.net>",
  :license     => "GPL3",
  :description => "Colorize nicks as they are being mentioned in messages.",
  :version     => "0.0.3",
  :gem_version => "0.0.3",
}

@config = Script::Config.new(
                             'whitelist_channels' => [Array, []],
                             'blacklist_channels' => [Array, []],
                             'blacklist_nicks'    => [Array, []],
                             'min_nick_length'    => [Integer, 1]
                             )

# FIXME do not colorize in URLs
# FIXME do not break existing colors of a message

PREFIX_COLORS = {
  '@' => 'nicklist_prefix1',
  '~' => 'nicklist_prefix1',
  '&' => 'nicklist_prefix1',
  '!' => 'nicklist_prefix1',
  '%' => 'nicklist_prefix2',
  '+' => 'nicklist_prefix3',
}

VALID_NICK = /([@~&!%+])?([-a-zA-Z0-9\[\]\\`_^\{|\}]+)/

def allowed_channel?(channel)
  begin
    channel_name = "#{channel.server.name}.#{channel.name}"
    if @config.whitelist_channels.empty?
      return !@config.blacklist_channels.include?(channel_name)
    else
      return @config.whitelist_channels.include?(channel_name)
    end
  rescue
    # this works around a bug in weechat which populates the channels
    # infolist too late
    return false
  end
end

def setup
  Modifiers::Print.new do |plugin, buffer, tags, line|
    # FIXME this will ignore your own actions (/me) due to a weechat bug
    if buffer.channel? && tags.include?("irc_privmsg") && allowed_channel?(buffer.channel)
      colors = {}
      buffer.channel.nicks.each do |nick|
        colors[nick.name] = nick.color
      end
      reset = Weechat.get_color("reset")

      line.message.gsub!(VALID_NICK) { |m|
        prefix, nick = $1 || "", $2
        prefix_color = nil
        nick_color   = nil
        if !@config.blacklist_nicks.include?(nick) && nick.size >= @config.min_nick_length && colors[nick]
          nick_color = colors[nick]
          nick = nick_color + nick + reset

          if PREFIX_COLORS.has_key?(prefix)
            prefix_color = Weechat.color(PREFIX_COLORS[prefix])
            prefix[0,0] = prefix_color
          end
        end

        prefix + nick
      }
    end

    line
  end
end

