# -*- ruby -*-

require 'rubygems'
require 'hoe'
require './lib/yodlee/version.rb'

HOE = Hoe.new('yodlee', Yodlee::VERSION) do |p|
  p.developer('Andrew A. Smith', 'andy@tinnedfruit.org')
  p.extra_deps = %w(mechanize nokogiri)
  p.extra_dev_deps = %w(flexmock)
end

missing = (HOE.extra_deps + HOE.extra_dev_deps).
  reject { |d| Gem.available? *d }

unless missing.empty?
  abort "You're missing gems. Try:\ngem install #{missing.join(' ')}"
end

# vim: syntax=Ruby
