#! /usr/bin/env ruby

require 'bundler/setup'
require 'eventmachine'
require 'em-http-request'
require 'em-dextras'
require 'json'

require_relative './fetch_list_of_countries'
require_relative './parse_worldbank_document'
require_relative './fetch_indicator'
require_relative './for_gnuplot'

INCOME_SHARE_BY_TOP_10PC = 'SI.DST.10TH.10'

class Monitoring
  def end_of_chain!(value)
    EM.stop
  end

  def inform_exception!(exception, stage)
    STDERR.puts "Error: #{exception} #{exception.backtrace.join("\n") if exception.respond_to?(:backtrace)}"
  end
end

class Print
  include EMDextras::Chains::SynchronousStage
  def invoke(input)
    puts input
  end
end

EM.run do
  EMDextras::Chains.pipe('no input', Monitoring.new, [
    FetchListOfCountries.new,
    ParseWorldbankDocument.new,
    :split,
    FetchIndicator.new(INCOME_SHARE_BY_TOP_10PC),
    ParseWorldbankDocument.new,
    :split,
    ForGnuplot.new,
    Print.new
  ], debug: true)
end
