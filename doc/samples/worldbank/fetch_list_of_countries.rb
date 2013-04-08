class FetchListOfCountries
  def todo(no_input)
    http = EventMachine::HttpRequest.new(list_of_countries_url)
    http.get
  end

  private

  def list_of_countries_url
    'http://api.worldbank.org/countries?format=json'
  end
end
