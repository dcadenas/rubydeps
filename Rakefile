require 'rubygems'
require 'rake'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |t|
    t.rspec_opts = ["-f progress", "-r ./spec/spec_helper.rb"]
    t.pattern = 'spec/*_spec.rb'
  end


task :default => :spec
