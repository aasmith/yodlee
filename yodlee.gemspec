# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{yodlee}
  s.version = "0.0.1.20090227002742"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Andrew A. Smith"]
  s.date = %q{2009-02-27}
  s.description = %q{Fetches accounts and their transaction details from the Yodlee  MoneyCenter (https://moneycenter.yodlee.com).}
  s.email = ["andy@tinnedfruit.org"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.rdoc"]
  s.files = ["History.txt", "Manifest.txt", "README.rdoc", "Rakefile", "lib/yodlee.rb", "lib/yodlee/account.rb", "lib/yodlee/connection.rb", "lib/yodlee/credentials.rb", "lib/yodlee/exceptions.rb", "lib/yodlee/monkeypatches.rb", "lib/yodlee/version.rb", "test/test_yodlee.rb", "yodlee.gemspec"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/aasmith/yodlee}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{yodlee}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Fetches financial data from Yodlee MoneyCenter.}
  s.test_files = ["test/test_yodlee.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<mechanize>, [">= 0"])
      s.add_runtime_dependency(%q<nokogiri>, [">= 0"])
      s.add_development_dependency(%q<flexmock>, [">= 0"])
      s.add_development_dependency(%q<hoe>, [">= 1.9.0"])
    else
      s.add_dependency(%q<mechanize>, [">= 0"])
      s.add_dependency(%q<nokogiri>, [">= 0"])
      s.add_dependency(%q<flexmock>, [">= 0"])
      s.add_dependency(%q<hoe>, [">= 1.9.0"])
    end
  else
    s.add_dependency(%q<mechanize>, [">= 0"])
    s.add_dependency(%q<nokogiri>, [">= 0"])
    s.add_dependency(%q<flexmock>, [">= 0"])
    s.add_dependency(%q<hoe>, [">= 1.9.0"])
  end
end
