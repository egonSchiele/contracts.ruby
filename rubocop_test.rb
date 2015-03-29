if RUBY_VERSION =~ /^2.1/
  puts `bundle && bundle exec rubocop --config rubocop.yml #{ARGV.join(" ")}`
end
