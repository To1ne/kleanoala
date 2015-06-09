ENV["RACK_ENV"] = "test"

require "./app"
require "test/unit"
require "rack/test"

class KleanoalaTest < Test::Unit::TestCase
  def test_it_404s_when_no_cleaner_are_set
    browser = Rack::Test::Session.new(Rack::MockSession.new(Sinatra::Application))
    browser.get "/now"
    assert browser.last_response.not_found?
  end

  def test_it_cannot_set_cleaners_without_login
    browser = Rack::Test::Session.new(Rack::MockSession.new(Sinatra::Application))
    data = {}
    data["startdate"] = "2015/12/25"
    data["cleaners"] = [ "one", "two", "three" ]
    browser.put "/cleaners", data.to_json
    assert browser.last_response.unauthorized?
  end
end
