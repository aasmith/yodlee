# -*- ruby -*-

require 'rubygems'
require 'hoe'
require './lib/yodlee/version.rb'

HOE = Hoe.new('yodlee', Yodlee::VERSION) do |p|
  p.developer('Andrew A. Smith', 'andy@tinnedfruit.org')
  p.extra_deps = %w(mechanize nokogiri)
  p.extra_dev_deps = %w(flexmock)
  p.summary = "Fetches financial data from Yodlee MoneyCenter."
end

missing = (HOE.extra_deps + HOE.extra_dev_deps).
  reject { |d| Gem.available? *d }

unless missing.empty?
  puts "You may be missing gems. Try:\ngem install #{missing.join(' ')}"
end

# vim: syntax=Ruby
