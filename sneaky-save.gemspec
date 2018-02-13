# -*- encoding: utf-8 -*-

version = File.read(File.expand_path("VERSION", __dir__)).strip

Gem::Specification.new do |s|
  s.name = %q{sneaky-save}
  s.version = version

  s.date = %q{2016-08-06}
  s.authors = ["Sergei Zinin (einzige)"]
  s.email = %q{szinin@gmail.com}
  s.homepage = %q{http://github.com/einzige/sneaky-save}

  s.licenses = ["MIT"]

  s.files = `git ls-files`.split("\n")
  s.require_paths = ["lib"]
  s.extra_rdoc_files = ["README.md"]

  s.description = %q{ActiveRecord extension. Allows to save record without calling callbacks and validations.}
  s.summary = %q{Allows to save record without calling callbacks and validations.}

  s.add_runtime_dependency 'activerecord', ">= 3.2.0"
  s.add_development_dependency 'rspec'
end
