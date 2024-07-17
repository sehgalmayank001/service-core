# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "rubocop/rake_task"

RuboCop::RakeTask.new

task default: %i[spec rubocop]

desc "Tag and push the current version"
task :release do
  version = `ruby -r ./lib/service_core/version -e "puts ServiceCore::VERSION"`.strip
  sh "git add ."
  sh "git commit -m 'Prepare for version #{version} release'"
  sh "git tag v#{version}"
  sh "git push origin main --tags"
end