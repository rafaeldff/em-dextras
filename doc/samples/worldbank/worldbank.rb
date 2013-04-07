require 'eventmachine'
require 'em-http-request'
require 'em-dextras'

require_relative './list_countries'

class Monitoring
  def end_of_chain!(value)
    puts "end!"
    EM.stop
  end
end

class PrintResponse
  include EMDextras::Chains::SynchronousStage
  def invoke(input)
    puts input.response
  end
end

EM.run do
  EMDextras::Chains.pipe('no input', Monitoring.new, [
    ListCountries.new,
    PrintResponse.new
  ])
end
