require "tempfile"
require "rake/testtask"

desc "Run the tests"
task :default do
  file = Tempfile.new(["kleanoala-test", ".db"])
  ENV["DATABASE_URL"] = "sqlite3://#{file.path}"
  ENV['RACK_ENV'] = "test"
  Rake::Task["test"].invoke
  file.unlink
end

Rake::TestTask.new do |t|
  t.test_files = [ "test.rb" ]
  # t.verbose = true
end
