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
    @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == ["admin", ENV["ADMIN_PASSWORD"]]
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

def cleaner_for_week(week)
  info = Info.first || halt(404)
  cleaners = Cleaner.all(:sequence.gte => 0, :order => :sequence) || halt(404)

  now = Time.now
  today = Time.new(now.year, now.month, now.day)
  index = (((today - info.startdate.to_time) / ONE_WEEK) + week) % cleaners.count
  cleaners[index.to_i]
end

def parse_date(date)
  if date.is_a? String
    date = DateTime.strptime(date, "%Y/%m/%d") || halt(500)
  end
  date = date.to_date if date.is_a? DateTime
  until date.wday == 1
    date -= 1
  end
  date
end

get "/" do
  content_type :json
  redirect to("/now")
end

get "/now" do
  content_type :json
  cleaner_for_week(0).to_json
end

get "/next/?:week?" do
  week = params[:week] ? params[:week].to_i : 1
  content_type :json
  cleaner_for_week(week).to_json
end

put "/configure" do
  protected!
  content_type :json
  request.body.rewind  # in case someone already read it
  data = JSON.parse request.body.read || halt(500)

  # set all cleaners inactive
  Cleaner.each do |cleaner|
    cleaner.sequence = -1
    cleaner.save!
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
  info.startdate = parse_date(data["startdate"])
  info.updated = DateTime.now
  info.save!
  p Cleaner.all(:sequence.gte => 0, :order => :sequence)

  redirect to("/now")
end

put "/push_front/:name" do
  protected!
  the_one = Cleaner.first(name: params[:name]) || halt(404)

  first = cleaner_for_week(0)
  count = Cleaner.last(order: :sequence)[:sequence]
  # reorder cleaners so it starts from this week
  cleaners = Cleaner.all(:sequence.gte => 0, :order => :sequence)
  cleaners.all(:sequence.lt => first.sequence).each do |cleaner|
    cleaner.sequence += count
    cleaner.save
  end
  # reprogram the sequence numbers
  sequence = 1
  cleaners.all(order: :sequence).each do |cleaner|
    p "cleaner: #{cleaner.id}. #{cleaner.name} #{cleaner.sequence} == #{the_one.id}"
    if cleaner.id == the_one.id
      cleaner.sequence = 0
      cleaner.save!
      next
    end
    cleaner.sequence = sequence
    cleaner.save!
    sequence += 1
  end
  p Cleaner.all(:sequence.gte => 0, :order => :sequence).map { |c| { c.name => c.sequence } }

  # update the info
  info = Info.first_or_create
  info.startdate = parse_date(Time.now) || halt(500)
  info.updated = DateTime.now
  info.save!

  redirect to("/now")
end
