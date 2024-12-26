# frozen_string_literal: true

source "https://rubygems.org"

gemspec

group :test do
  gem "aruba"
  if RUBY_VERSION >= '3.4'
    # Cucumber is broken on Ruby 3.4, requires the fix in
    # https://github.com/cucumber/cucumber-ruby/pull/1757
    gem "cucumber", ">= 9.2", git: 'https://github.com/cucumber/cucumber-ruby'
  else
    gem "cucumber", "~> 9.2"
  end
  gem "rspec"

  gem "rubocop", ">= 1.0.0"
  gem "rubocop-performance", ">= 1.0.0"
end

group :development do
  gem "method_profiler"
  gem "rake"
  gem "relish"
  gem "ruby-prof"
end
