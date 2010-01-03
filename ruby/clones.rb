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
#   2009-12-31, Dominik Honnef <dominikho@gmx.net>:
#       version 0.0.1
#
###############################################################################
=end

require 'weechat'
include Weechat
include Script::Skeleton
include Weechat::Helper

@script = {
  :name        => "clones",
  :author      => "Dominik Honnef <dominikho@gmx.net>",
  :license     => "GPL3",
  :description => "Determines 'clones' i.e. users with the same hostmask.",
  :version     => "0.0.1",
  :gem_version => "0.0.5",
}

@config = Script::Config.new(
                             'show_in_current_buffer'     => [Boolean, false]
                             )


def setup
  Command.new(:command     => "/clones",
              :description => "Display clones.",
              :args        => "[channel]",
              :args_description => {
                "channel"  => "The channel to scan. Defaults to the current one",
              },
              :completion => ["channel %(channels)"]) do |buffer, args|
    msg_target = @config.show_in_current_buffer ? buffer : Weechat

    begin
      if args.empty?
        channel = buffer.channel
      else
        cbuffer = Buffer.find("irc", args)
        if cbuffer
          channel = cbuffer.channel
        elsif buffer.server
          channel = buffer.server.channels.find {|channel| channel.name == args}
        else
          channel = nil
        end

        raise Exception::NotAChannel if channel.nil?
      end
    rescue Exception::NotAChannel
      msg = "You did not specify a valid channel to check."
      msg_target.puts msg
      raise Exception::WEECHAT_RC_ERROR
    end

    hosts = Hash.new {|h,k| h[k] = []}
    channel.users.each do |user|
      hosts[user.host.host] << user
    end

    bold      = Weechat::Color::Bold
    underline = Weechat::Color::Underline
    reset     = Weechat::Color::Reset

    msg_target.puts "#{bold}Clones found for #{channel.name}:#{reset}"
    hosts.each do |host, users|
      if users.size > 1
        msg_target.puts "  #{underline}#{host}#{reset}:"
        users.each do |user|
          msg_target.puts "  - #{user.color}#{user.name}#{reset}"
        end
      end
    end
  end
end
