if RUBY_VERSION.to_f >= 2.1
  puts "running rubocop..."
  puts `bundle exec rubocop --config rubocop.yml #{ARGV.join(" ")} -D`
  exit $?.exitstatus
end
