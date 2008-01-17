# require_dependency 'application'
require File.dirname(__FILE__)+'/lib/tagging_methods'

class TagsExtension < Radiant::Extension
  version "1.0"
  description "Makes pages taggable"
  url "http://yourwebsite.com/tags"
  
  def activate
    raise "The Shards extension is required and must be loaded first!" unless defined?(Shards)
    Radiant::Config['tag.results_page_url'] = '/search/by-tag'
    TagSearchPage
    Page.send :include, RadiusTags
    require 'tagging_methods'
    begin
      MetaTag
    rescue
      # dirty hack; need to get trough here to allow migrations to run..
    end
    admin.page.edit.add :extended_metadata, 'tag_field'
  end
  
  def deactivate
    admin.tabs.remove "Tags"
  end
  
  def load_config
    filename = File.join(TagsExtension.root, 'config', 'tags.yml')
    raise TagsExtensionError.new("TagsExtension error: configuration file does not exist, see the README") unless File.exists?(filename)
    configurations = YAML::load_file(filename)
    configurations.each do |key, value|
      Radiant::Config["#{key}"] = value
    end
  end
end