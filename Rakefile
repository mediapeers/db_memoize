require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task "db:test:create" do
  Rake.sh "dropdb db_memoize_test || true"
  Rake.sh "createdb db_memoize_test"
end

task :default => %w(db:test:create spec)
