require 'rubygems'
require 'rake'

spec = Gem::Specification.new do |s|
  s.extensions = FileList["ext/**/extconf.rb"]
  s.name = "rubydeps"
  s.summary = %Q{A tool to create class dependency graphs from test suites}
  s.description = %Q{A tool to create class dependency graphs from test suites}
  s.email = "dcadenas@gmail.com"
  s.homepage = "http://github.com/dcadenas/rubydeps"
  s.authors = ["Daniel Cadenas"]
  s.executables = ["rubydeps"]

  s.add_development_dependency(%q<rake-compiler>, ["~> 0.8"])
  s.add_development_dependency(%q<rspec>, ["~> 2.13"])
  s.add_development_dependency(%q<file_test_helper>, ["~> 1.0"])
  s.add_dependency(%q<debugger-ruby_core_source>, ["~> 1.2"])
  s.add_dependency(%q<ruby-graphviz>, ["~> 1.0"])
  s.add_dependency(%q<thor>, ["~> 0.18"])

  s.version = File.read("VERSION")
  s.files = `git ls-files`.split
end

require 'rake/extensiontask'
Gem::PackageTask.new(spec) do |pkg|
end

Rake::ExtensionTask.new('call_site_analyzer', spec)

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = ["-f progress", "-r ./spec/spec_helper.rb"]
  t.pattern = 'spec/*_spec.rb'
end

task :spec => :compile

task :default => :spec
