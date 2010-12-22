
$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'rubygems'
require 'rspec'
require 'active_support/all'
require 'active_record'
#require File.dirname(__FILE__) + '/../init'

RSpec.configure do |config|
  config.mock_with :rspec
end
