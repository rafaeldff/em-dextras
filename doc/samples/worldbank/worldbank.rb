#! /usr/bin/env ruby

require 'bundler/setup'
require 'eventmachine'
require 'em-http-request'
require 'em-dextras'
require 'json'

require_relative './fetch_list_of_countries'
require_relative './parse_list_of_countries'
require_relative './fetch_indicator'

INCOME_SHARE_BY_TOP_10PC = 'SI.DST.10TH.10'

class Monitoring
  def end_of_chain!(value)
    puts "end!"
    EM.stop
  end
end

class Print
  include EMDextras::Chains::SynchronousStage
  def invoke(input)
    @count ||= 0
    @count += 1
    puts "#@count: #{input.inspect[0..20]}"
  end
end

EM.run do
  EMDextras::Chains.pipe('no input', Monitoring.new, [
    FetchListOfCountries.new,
    ParseListOfCountries.new,
    :split,
    FetchIndicator.new(INCOME_SHARE_BY_TOP_10PC),
    Print.new
  ])
end
