Gem::Specification.new do |s|
  s.name = %q{rubydeps}
  s.version = "0.9.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Daniel Cadenas"]
  s.date = %q{2010-09-28}
  s.description = %q{Graphs ruby dependencies}
  s.email = %q{dcadenas@gmail.com}
  s.executables = ["rubydeps"]
  s.extra_rdoc_files = [
    "LICENSE"
  ]
  s.files = [
    ".document",
    ".gitignore",
    "LICENSE",
    "README.md",
    "bin/rubydeps",
    "lib/rubydeps.rb"
  ]
  s.homepage = %q{http://github.com/dcadenas/rubydeps}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Graphs ruby depencencies}
  s.test_files = [
    "spec/rubydeps_spec.rb",
    "spec/spec_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake-compiler>, ["~> 0.8.0"])
      s.add_development_dependency(%q<rspec>, ["~> 2.8.0"])
      s.add_development_dependency(%q<file_test_helper>, ["~> 1.0.0"])
      s.add_dependency(%q<ruby-graphviz>, ["~> 1.0.5"])
      s.add_dependency(%q<thor>, ["~> 0.14.2"])
    else
      s.add_dependency(%q<rake-compiler>, ["~> 0.8.0"])
      s.add_dependency(%q<rspec>, [">= 2.8.0"])
      s.add_dependency(%q<file_test_helper>, ["~> 1.0.0"])
      s.add_dependency(%q<ruby-graphviz>, ["~> 1.0.5"])
      s.add_dependency(%q<thor>, ["~> 0.14.2"])
    end
  else
    s.add_dependency(%q<rake-compiler>, ["~> 0.8.0"])
    s.add_dependency(%q<rspec>, [">= 2.8.0"])
    s.add_dependency(%q<file_test_helper>, ["~> 1.0.0"])
    s.add_dependency(%q<ruby-graphviz>, ["~> 1.0.5"])
    s.add_dependency(%q<thor>, ["~> 0.14.2"])
  end
end

