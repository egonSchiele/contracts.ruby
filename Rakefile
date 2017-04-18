if RUBY_VERSION >= "2"
  task :default => [:spec, :rubocop]

  require "rubocop/rake_task"
  RuboCop::RakeTask.new
else
  task :default => [:spec]
end

task :add_tag do
  `git tag -a v#{Contracts::VERSION} -m 'v#{Contracts::VERSION}'`
end

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)
