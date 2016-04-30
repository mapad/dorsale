source "https://rubygems.org"

ruby_version_file = File.join(__dir__, ".ruby-version")
if File.exists?(ruby_version_file)
  ruby File.read(ruby_version_file).strip
else
  puts ".ruby-version file not found"
end

gem "rails", "~> 4.2.1"
gem "devise"
gem "devise-bootstrap-views"
gem "devise-i18n"

gemspec

group :production, :development do
  gem 'pg'
  gem 'uglifier'
  gem "whenever"
  gem "exception_notification"
end

group :development, :test do
  gem "test_after_commit"
  gem "database_cleaner"
  gem "thor"
  gem "pry"
  gem "sqlite3"
  gem "zeus"
  gem "rspec-rails"
  gem "minitest"
  gem "shoulda-matchers", "2.5.0"
  gem "faker"
  gem "cucumber-rails", require: false
  gem "capybara"
  gem "poltergeist"
  gem "factory_girl_rails"
  gem "guard"
  gem "guard-cucumber"
  gem "guard-rspec"
  gem "guard-rubocop"
  gem "timecop"
  gem "pdf-inspector"
  gem "yomu"
end
