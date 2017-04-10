# frozen_string_literal: true
source "https://rubygems.org"

ruby RUBY_VERSION

gem "rake"
gem "faraday", "0.11.0"
gem "pry"

group :test do
  gem "rspec", "3.5.0"
  gem "toxiproxy", "1.0.0"
end

group :test, :development do
  gem "vcr", "3.0.3"
  gem "webmock", "2.3.2"
end
