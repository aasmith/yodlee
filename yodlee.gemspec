# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{yodlee}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Andrew A. Smith"]
  s.date = %q{2009-02-02}
  s.description = %q{Fetches accounts and their transaction details from the Yodlee  MoneyCenter (https://moneycenter.yodlee.com).}
  s.email = ["andy@tinnedfruit.org"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.txt"]
  s.files = ["History.txt", "Manifest.txt", "README.txt", "Rakefile", "lib/yodlee.rb", "test/test_yodlee.rb"]
  s.has_rdoc = true
  s.homepage = %q{ * http://github.com/aasmith/yodlee}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{yodlee}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Fetches accounts and their transaction details from the Yodlee  MoneyCenter (https://moneycenter.yodlee.com).}
  s.test_files = ["test/test_yodlee.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<hoe>, [">= 1.8.3"])
    else
      s.add_dependency(%q<hoe>, [">= 1.8.3"])
    end
  else
    s.add_dependency(%q<hoe>, [">= 1.8.3"])
  end
end
