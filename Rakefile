require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task 'db:test:create' do
  Rake.sh 'dropdb db_memoize_test -U postgres || true'
  Rake.sh 'createdb db_memoize_test -U postgres'
end

task :default => %w(db:test:create spec)

desc "release a new development gem version"
task :release do
  sh "scripts/release.rb"
end

desc "release a new stable gem version"
task "release:stable" do
  sh "BRANCH=stable scripts/release.rb"
end
