if RUBY_VERSION =~ /^2.1/
  puts `bundle exec rubocop --config rubocop.yml #{ARGV.join(" ")}`
end
