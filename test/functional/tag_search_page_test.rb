require File.dirname(__FILE__) + '/../test_helper'

class TagSearchPageTest < Test::Unit::TestCase
  
  fixtures :pages, :meta_tags, :taggings, :page_parts
  
  def setup
    @page = pages(:tags_page)
    @page.request = ActionController::TestRequest.new
    @page.response = ActionController::TestResponse.new
  end
  
  def test_title_gets_set_ok
    @page.request.request_parameters = {:tag => "foo"}
    @page.render
    assert_equal "Tagged with foo", @page.title
  end
  
  def test_no_title_means_no_title_change
    @page.render
    assert_equal "Tags Page", @page.title
  end
  
  def test_page_should_show_posts_tagged_with_tag
    @page.request.request_parameters = {:tag => "lorem"}
    output = @page.render
    assert_match /These pages are tagged with "lorem"/, output
    assert_match /Ruby Home Page/, output
    assert_match /Documentation/, output
  end
  
  def test_resulting_pages_should_be_sorted
    @page.request.request_parameters = {:tag => "lorem"}
    output = @page.render
    assert_match /Documentation.*Ruby Home Page/, output
  end
  
  def test_unknown_tag_should_say_so
    @page.request.request_parameters = {:tag => "foobarbar"}
    output = @page.render
    assert_match /No pages tagged with "foobarbar"/, output
  end
  
end