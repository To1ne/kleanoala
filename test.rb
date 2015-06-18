# coding: utf-8
ENV["RACK_ENV"] = "test"
ENV["ADMIN_PASSWORD"] = "le mot de passe"

require "./app"
require "test/unit"
require "rack/test"

class KleanoalaTest < Test::Unit::TestCase
  # thanks to https://github.com/brynary/rack-test
  def basic_authorize(username, password)
    encoded_login = ["#{username}:#{password}"].pack("m*")
    @browser.header "Authorization", "Basic #{encoded_login}"
  end

  def test_it_404s_when_no_cleaner_are_set
    @browser = Rack::Test::Session.new(Rack::MockSession.new(Sinatra::Application))
    @browser.get "/now"
    assert @browser.last_response.not_found?
  end

  def test_it_cannot_set_cleaners_without_login
    @browser = Rack::Test::Session.new(Rack::MockSession.new(Sinatra::Application))
    data = {startdate: "2015/12/25", cleaners: [ "one", "two", "three" ] }.to_json
    @browser.put "/configure", data, "Content-Type" => "application/json"
    assert @browser.last_response.unauthorized?
  end
  
  def test_it_can_set_cleaners
    @browser = Rack::Test::Session.new(Rack::MockSession.new(Sinatra::Application))
    data = {startdate: "2015/12/25", cleaners: [ "one", "two", "three" ] }.to_json
    basic_authorize "admin", ENV["ADMIN_PASSWORD"]
    @browser.put "/configure", data, "Content-Type" => "application/json"
    assert @browser.last_response.redirection?
  end

  def test_it_can_get_the_current_cleaner
    @browser = Rack::Test::Session.new(Rack::MockSession.new(Sinatra::Application))

    data = {startdate: "2015/12/25", cleaners: [ "one", "two", "three" ] }.to_json
    basic_authorize "admin", ENV["ADMIN_PASSWORD"]
    @browser.put "/configure", data, "Content-Type" => "application/json"

    @browser.get "/now"
    assert @browser.last_response.ok?
    assert JSON.parse(@browser.last_response.body)
  end

  def test_it_can_get_the_cleaner_for_next_week
    @browser = Rack::Test::Session.new(Rack::MockSession.new(Sinatra::Application))

    data = {startdate: "2015/12/25", cleaners: [ "one", "two", "three" ] }.to_json
    basic_authorize "admin", ENV["ADMIN_PASSWORD"]
    @browser.put "/configure", data, "Content-Type" => "application/json"

    @browser.get "/next"
    assert @browser.last_response.ok?
    assert JSON.parse(@browser.last_response.body)
  end

  def test_it_can_get_the_cleaner_for_week_x
    @browser = Rack::Test::Session.new(Rack::MockSession.new(Sinatra::Application))

    data = {startdate: "2015/12/25", cleaners: [ "one", "two", "three" ] }.to_json
    basic_authorize "admin", ENV["ADMIN_PASSWORD"]
    @browser.put "/configure", data, "Content-Type" => "application/json"

    [ 2, 3, 10, 100, 1000].each do |offset|
      @browser.get "/next/#{offset}"
      assert @browser.last_response.ok?
      assert JSON.parse(@browser.last_response.body)
    end
  end

  def test_it_returns_same_cleaner_for_week_1_and_next
    @browser = Rack::Test::Session.new(Rack::MockSession.new(Sinatra::Application))

    data = {startdate: "2015/12/25", cleaners: [ "one", "two", "three" ] }.to_json
    basic_authorize "admin", ENV["ADMIN_PASSWORD"]
    @browser.put "/configure", data, "Content-Type" => "application/json"

    @browser.get "/next"
    val = JSON.parse(@browser.last_response.body)["name"]

    @browser.get "/next/1"
    assert_equal val, JSON.parse(@browser.last_response.body)["name"]
  end

  def test_it_gives_everybody_a_turn
    @browser = Rack::Test::Session.new(Rack::MockSession.new(Sinatra::Application))

    everybody = { "one" => 1, "two" => 1, "three" => 1 }
    data = {startdate: "2015/12/25", cleaners: everybody.keys }.to_json
    basic_authorize "admin", ENV["ADMIN_PASSWORD"]
    @browser.put "/configure", data, "Content-Type" => "application/json"

    counter = 0
    while everybody.has_value?(1) do
      @browser.get "/next/#{counter}"
      name = JSON.parse(@browser.last_response.body)["name"]
      assert_equal 1, everybody[name]
      everybody[name] -= 1
      counter += 1
    end
  end
end
