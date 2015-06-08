# coding: utf-8
require "sinatra"
require "data_mapper"
require "i18n"
require "json"

ONE_WEEK = 3600 * 24 * 7

helpers do
  def protected!
    return if authorized?
    headers["WWW-Authenticate"] = "Basic realm='Restricted Area'"
    halt 401, "Not authorized\n"
  end

  def authorized?
    @auth ||= Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == ["admin", ENV["ADMIN_PASSWORD"]]
  end
end

DataMapper.setup(:default, ENV["DATABASE_URL"] || "sqlite3://#{Dir.pwd}/my.db")

class Info
  include DataMapper::Resource

  property :id, Serial
  property :startdate, Date
  property :updated, DateTime
end

class Cleaner
  include DataMapper::Resource

  property :id, Serial
  property :name, String
  property :sequence, Integer

  has n, :log_items
end

class LogItem
  include DataMapper::Resource

  property :id, Serial
  property :date, Date

  belongs_to :cleaner
end

DataMapper.finalize.auto_upgrade!

get "/" do 
  content_type :json
  redirect to("/now")
end

get "/now" do
  content_type :json
  info = Info.first || halt(500)
  cleaners = Cleaner.all(order: :sequence) || halt(500)

  now = Time.now
  today = Time.new(now.year, now.month, now.day)
  offset = ((today - info.startdate.to_time) / ONE_WEEK) % cleaners.count
  p cleaners
  @cleaner = cleaners[offset.to_i]
  @cleaner.to_json
end

put "/cleaners" do
  protected!
  content_type :json
  request.body.rewind  # in case someone already read it
  data = JSON.parse request.body.read || halt(500)

  # set all cleaners inactive
  Cleaner.each do |cleaner|
    cleaner.sequence = -1
  end

  # reorder the active cleaners
  sequence = 0
  data["cleaners"].each do |name|
    cleaner = Cleaner.first_or_create(name: name)
    cleaner.sequence = sequence
    cleaner.save!
    sequence += 1
  end

  # update the info
  info = Info.first_or_create
  info.startdate = DateTime.strptime(data["startdate"], "%Y/%m/%d") || halt(500)
  info.updated = DateTime.now
  info.save!

  redirect to("/get")
end
