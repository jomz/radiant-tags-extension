require File.dirname(__FILE__) + '/../test_helper'

class PageTaggabilityTest < Test::Unit::TestCase
  def setup
    @page = Page.find 1
  end
  
  def test_page_should_be_taggable
    assert true, @page.respond_to?("tag_with")
    assert_difference MetaTag, :count, 2 do
      @page.tag_with 'lorem ipsum'
    end
  end
  
  def assert_difference(object, method = nil, difference = 1)
    initial_value = object.send(method)
    yield
    assert_equal initial_value + difference, object.send(method), "#{object}##{method}"
  end
end