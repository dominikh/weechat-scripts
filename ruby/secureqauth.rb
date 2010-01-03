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
#   2009-12-26, Dominik Honnef <dominikho@gmx.net>:
#       version 0.0.1
#
###############################################################################
=end

require 'weechat'
require 'openssl'
include Weechat

@script = {
  :name        => "secureqauth",
  :author      => "Dominik Honnef <dominikho@gmx.net>",
  :license     => "GPL3",
  :description => "Securely identify with quakenet services.",
  :version     => "0.0.1",
  :gem_version => "0.0.6",
}

# server => {:username, :password_hash}
@requests = {}
@digest = OpenSSL::Digest::Digest.new("sha256")


# TODO support other hashes than SHA-256

def calculate_q_hash(username, password_hash, challenge)
  username = username.irc_downcase

  key           = OpenSSL::Digest::SHA256.hexdigest("#{username}:#{password_hash}")
  response      = OpenSSL::HMAC.hexdigest(@digest, key, challenge)
end

def setup
  Command.new(:command     => "/secureqauth",
              :description => "Auth with Q using CHALLENGEAUTH",
              :args        => "[username] [password]",
              :args_description => {
                "username"  => "Your username",
                "password"  => "Your password",
              }) do |buffer, args|

    server = buffer.server
    if server.nil?
      Weechat.puts "Not a valid IRC server."
      raise Exception::WEECHAT_RC_ERROR
    end

    username, password = args.split(" ")
    raise Exception::WEECHAT_RC_ERROR if username.nil? or password.nil?

    @requests[server] = {
      :username => username,
      :password_hash => OpenSSL::Digest::SHA256.hexdigest(password[0, 10]),
    }

    Weechat.puts("Authenticating as #{username}...")
    buffer.exec("/quote PRIVMSG Q@CServe.quakenet.org :CHALLENGE")
  end

  Modifier.new("irc_in_notice") do |server, message|
    ret = message
    message = message.message

    if @requests[server]
      parts   = message.split(" ")
      if parts.size > 5
        host    = parts[0][1..-1]
        command = parts[3][1..-1]

        if host == "Q!TheQBot@CServe.quakenet.org" && command == "CHALLENGE"
          username, password_hash = @requests[server].values_at(:username, :password_hash)
          challenge = parts[4]
          response = calculate_q_hash(username, password_hash, challenge)

          Weechat.puts("Sending challengeauth for #{username}...")
          server.buffer.exec("/quote PRIVMSG Q@CServe.quakenet.org :CHALLENGEAUTH #{username} #{response} HMAC-SHA-256")

          ret = ""
          @requests.delete server
        end
      end
    end

    ret
  end
end
