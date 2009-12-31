
require 'weechat'
include Weechat
include Script::Skeleton
include Weechat::Helper

@script = {
  :name        => "input_length",
  :author      => "Dominik Honnef <dominikho@gmx.net>",
  :license     => "GPL3",
  :description => "Provides a bar item displaying the current length of the input",
  :version     => "0.0.1",
  :gem_version => "0.0.5",
}

class InputLength < Bar::Item
  def build_item(window)
    window.buffer.input.length
  end

  def initialize(*args)
    super("input_length", &method(:build_item))
    Weechat::Hooks::Signal.new("input_text_changed") {update}
  end
end

def setup
  @item = InputLength.new
end
