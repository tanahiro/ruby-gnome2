#!/usr/bin/env ruby

require 'gst'

if ARGV.size != 1
  puts "Usage: #{$0} audio-file"
  exit
end

file = ARGV.first

pipeline = Gst::Pipeline.new

file_src = Gst::ElementFactory.make("filesrc")
file_src.location = file

decoder = Gst::ElementFactory.make("decodebin")

audio_convert = Gst::ElementFactory.make("audioconvert")

audio_resample = Gst::ElementFactory.make("audioresample")

audio_sink = Gst::ElementFactory.make("autoaudiosink")

pipeline.add(file_src, decoder, audio_convert, audio_resample, audio_sink)
file_src >> decoder
audio_convert >> audio_resample >> audio_sink

decoder.signal_connect("new-decoded-pad") do |element, pad|
  sink_pad = audio_convert["sink"]
  pad.link(sink_pad)
end

loop = GLib::MainLoop.new(nil, false)

bus = pipeline.bus
bus.add_watch do |bus, message|
  case message.type
  when Gst::Message::EOS
    loop.quit
  when Gst::Message::ERROR
    p message.parse
    loop.quit
  end
  true
end

pipeline.play
begin
  loop.run
rescue Interrupt
ensure
  pipeline.stop
end
