require 'eventmachine'
require 'em-http-request'
require 'em-dextras'

def list_of_countries_url
  'http://api.worldbank.org/countries'
end

EM.run do
  http = EventMachine::HttpRequest.new(list_of_countries_url)
  request = http.get query: {format: 'json'}
  request.callback do 
    p request.response
    EM.stop
  end
end
