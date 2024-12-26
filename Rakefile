# frozen_string_literal: true

task :default => [:spec]

task :cucumber do
  if RUBY_VERSION >= "3.4"
    sh "cucumber --tags 'not @before_ruby_3_3'"
  else
    sh "cucumber --tags 'not @after_ruby_3_4'"
  end
end

task :add_tag do
  `git tag -a v#{Contracts::VERSION} -m 'v#{Contracts::VERSION}'`
end

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)
