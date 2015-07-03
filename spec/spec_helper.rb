require 'rubygems'
$TESTING=true
require 'resque'
require 'coveralls'
Coveralls.wear!
$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

Spec::Matchers.define :have_key do |expected|
  match do |redis|
    redis.exists(expected)
  end
end
