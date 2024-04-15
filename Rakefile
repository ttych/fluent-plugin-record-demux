# frozen_string_literal: true

require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake/testtask'
Rake::TestTask.new(:test) do |t|
  t.libs.push('lib', 'test')
  t.test_files = FileList['test/**/test_*.rb', 'test/**/*_test.rb',]
  t.verbose = true
  t.warning = true
end

require 'rubocop/rake_task'
RuboCop::RakeTask.new

require 'bump/tasks'

task default: %i[test rubocop]
