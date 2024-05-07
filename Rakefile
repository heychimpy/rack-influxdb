require 'rubygems'
require 'bundler/setup'
require 'bundler/gem_tasks'
require 'rake/testtask'

namespace :test do
  Rake::TestTask.new(:all) do |t|
    t.pattern = "spec/**/*_spec.rb"
  end
end
