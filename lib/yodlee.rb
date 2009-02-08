require 'rubygems'
require 'mechanize'
require 'nokogiri'
require 'enumerator'
require 'time'

begin
  require 'johnson'
rescue LoadError
end

require 'yodlee/account'
require 'yodlee/connection'
require 'yodlee/credentials'
require 'yodlee/exceptions'
require 'yodlee/monkeypatches'
require 'yodlee/version'

module Yodlee
  class Transaction < Struct.new(
    :account_name, :account_id,
    :currency, :amount, :date,
    :fit_id, :status, :description
  )
  end
end
