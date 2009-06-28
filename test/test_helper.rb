require 'test/unit'
# Load the the environment
unless defined? RADIANT_ROOT
  ENV["RAILS_ENV"] = "test"
  require "#{File.expand_path(File.dirname(__FILE__) + "/../../../../")}/config/environment"
end
require "#{RADIANT_ROOT}/test/test_helper"

class Test::Unit::TestCase
  
  # Include a helper to make testing Radius tags easier
  test_helper :render
  
  # Add the fixture directory to the fixture path
  self.fixture_path << File.dirname(__FILE__) + "/fixtures"
  
  fixtures :users, :pages
  # Add more helper methods to be used by all extension tests here...
  
end