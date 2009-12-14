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
#   2009-12-13, Dominik Honnef <dominikho@gmx.net>:
#       version 0.0.1
#
###############################################################################
=end

require 'weechat'
include Weechat
include Script::Skeleton
include Weechat::Helper

@script = {
  :name        => "dim_annoying",
  :author      => "Dominik Honnef <dominikho@gmx.net>",
  :license     => "GPL3",
  :description => "A script for dimming lines of people you consider unimportant.",
  :version     => "0.0.1",
  :gem_version => "0.0.1",
}

@config = Script::Config.new(
                             'dimmed_nicks' => [Array, []],
                             'dim_nick'     => [Boolean, true],
                             'color'        => [Color, 'darkgray']
                             )


def setup
  Command.new(:command     => "/dim",
              :description => "Manage dims.",
              :args        => "[list] | [add|del [nick]]",
              :args_description => {
                "list"  => "List all dims",
                "add"   => "Adds a new dim",
                "del"   => "Removes a dim",
              },
              :completion => ["list", "add %(nicks)", "del %(nicks)"]) do |buffer, args|
    command, *nicks = args.shell_split

    case command
    when "list"
      Weechat.puts @config.dimmed_nicks.join("\n")
    when "add"
      @config.dimmed_nicks.concat nicks
      Weechat.puts("dimmed #{nicks.join(",")}")
    when "del"
      nicks.each {|nick| @config.dimmed_nicks.delete nick }
      Weechat.puts("undimmed #{nicks.join(",")}")
    else
      Weechat.exec("/help dim")
    end
  end

  Modifier.new("weechat_print") do |plugin, buffer, tags, line|
    if plugin.name == 'irc'
      prefix = line.prefix.strip_colors
      l      = line.message.strip_colors

      prefix.gsub!(/^[@+]/, '')
      if (!tags.include?("irc_action") && @config.dimmed_nicks.include?(prefix)) ||
          (tags.include?("irc_action") && @config.dimmed_nicks.any?{|nick|
             l.start_with?("#{nick} ")
           })


        if @config.dim_nick
          line.strip_colors!
          line[0,0] = @config.color.to_s
        else
          if tags.include?("irc_action")
            parts = line.message.split(" ")
            line.message = parts[0] + " " + @config.color.to_s + parts[1..-1].join(" ").strip_colors
          else
            line.message.strip_colors!
            line.message[0,0] = @config.color.to_s
          end
        end
      end
    end
    line.to_s
  end
end
