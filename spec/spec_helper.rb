require 'rubygems'
$TESTING=true
$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'resque'
require 'resque-scheduler'
require 'coveralls'
Coveralls.wear!

RSpec::Matchers.define :have_key do |expected|
  match do |redis|
    redis.exists(expected)
  end
end
