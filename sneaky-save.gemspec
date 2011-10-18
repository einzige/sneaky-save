# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{sneaky-save}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Sergei Zinin", "Kevin Goslar"]
  s.date = %q{2011-10-17}
  s.description = %q{ActiveRecord extension. Allows to save record without calling callbacks and validations.}
  s.email = %q{kgoslar@partyearth.com}
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]
  s.files = `git ls-files`.split("\n")
  s.homepage = %q{http://github.com/partyearth/sneaky-save}
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{Allows to save record without calling callbacks and validations.}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activerecord>, [">= 2.3.2"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.6.2"])
    else
      s.add_dependency(%q<activerecord>, [">= 2.3.2"])
      s.add_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.6.2"])
    end
  else
    s.add_dependency(%q<activerecord>, [">= 2.3.2"])
    s.add_dependency(%q<bundler>, ["~> 1.0.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.6.2"])
  end
end
