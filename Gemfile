source "http://rubygems.org"

gemspec

group :test do
  gem "rspec"
  gem "aruba"
  gem "cucumber", "~> 1.3.20"
  gem "rubocop", "~> 0.29.1" if RUBY_VERSION >= "2"
end

group :development do
  gem "relish"
  gem "method_profiler"
  gem "ruby-prof"
  gem "rake"
end
