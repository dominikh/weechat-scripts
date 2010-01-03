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
#   2009-12-21, Dominik Honnef <dominikho@gmx.net>:
#       version 0.0.1
#
###############################################################################
=end

require 'weechat'
include Weechat

require 'pp'
require 'stringio'

@script = {
  :name => 'ruby_eval',
  :author => 'Dominik Honnef <dominikho@gmx.net>',
  :version => '0.0.1',
  :gem_version => '0.0.6',
  :license => 'GPL3',
  :description => 'evals a given ruby expression',
}

def setup
  Weechat::Command.new("ruby_eval", "evals a ruby expression") do |buffer, message|
    eval_rb(buffer, message, :puts)
  end

  Weechat::Command.new("ruby_eval_o", "evals a ruby expression") do |buffer, message|
    eval_rb(buffer, message, :channel)
  end
end

def eval_rb(buffer, string, target = :puts)
  # valid targets: puts, channel
  old_stdout = $stdout
  io = StringIO.new
  $stdout = io
  begin
    ret = eval(string)
    s1 = "eval [ruby] [return]:    "
    if target == :puts
      s1 << ret.pretty_inspect
    else
      s1 << ret.inspect
    end
  rescue ::Exception => e
    s1 = "eval [ruby] [exception]: {#{e.class}} "
    s1 << e.message.split("\n").join("\n" + (" " * s1.size))
  end
  $stdout = old_stdout
  output = io.string
  s2 = nil
  unless output.empty?
    s2 = "eval [ruby] [output]:    " + output.inspect
  end

  s3 = "eval [ruby] [input]:     #{string}"
  case target
  when :puts
    buffer.puts s3
    buffer.puts s2 if s2
    buffer.puts s1
  when :channel
    buffer.say s3
    buffer.say s2 if s2
    buffer.say s1
  end
end
