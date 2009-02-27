require 'rubygems'
require 'hoe'
require './lib/yodlee/version.rb'

HOE = Hoe.new('yodlee', Yodlee::VERSION) do |p|
  p.developer 'Andrew A. Smith', 'andy@tinnedfruit.org'
  p.readme_file = "README.rdoc"
  p.extra_rdoc_files = [p.readme_file]
  p.extra_deps = %w(mechanize nokogiri)
  p.extra_dev_deps = %w(flexmock)
  p.summary = "Fetches financial data from Yodlee MoneyCenter."
end

missing = (HOE.extra_deps + HOE.extra_dev_deps).
  reject { |d| Gem.available? *d }

unless missing.empty?
  puts "You may be missing gems. Try:\ngem install #{missing.join(' ')}"
end

namespace :gem do
  desc 'Generate a gem spec'
  task :spec do
    File.open("#{HOE.name}.gemspec", 'w') do |f|
      HOE.spec.version = "#{HOE.version}.#{Time.now.strftime("%Y%m%d%H%M%S")}"
      f.write(HOE.spec.to_ruby)
    end
  end
end
