require File.dirname(__FILE__) + '/../test_helper'

class TagsExtensionTest < Test::Unit::TestCase
  
  fixtures :pages, :meta_tags, :taggings
  test_helper :render
  
  def setup
    @page = pages(:documentation)
  end
  
  def test_cloud_tag
    assert_renders "<ol class=\"tag_cloud\"><li class=\"size2\"><span>1 page is tagged with </span><a href=\"?q=dolor\" class=\"tag\">dolor</a></li><li class=\"size3\"><span>2 pages are tagged with </span><a href=\"?q=ipsum\" class=\"tag\">ipsum</a></li><li class=\"size3\"><span>2 pages are tagged with </span><a href=\"?q=lorem\" class=\"tag\">lorem</a></li></ol>", "<r:tag_cloud />"
  end
  
  def test_tag_list
    assert_renders "<a href=\"?q=ipsum\" class=\"tag\">ipsum</a>, <a href=\"?q=lorem\" class=\"tag\">lorem</a>", "<r:tag_list />"
  end
end