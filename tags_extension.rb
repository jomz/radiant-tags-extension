# require_dependency 'application'
require File.dirname(__FILE__)+'/lib/tagging_methods'

class TagsExtension < Radiant::Extension
  version "1.2"
  description "This extension enhances the page model with tagging capabilities, tagging as in \"2.0\" and tagclouds."
  url "http://gorilla-webdesign.be"  

  define_routes do |map|
    if defined?(SiteLanguage)  && SiteLanguage.count > 0
      include Globalize
      SiteLanguage.codes.each do |code|
        langname = Locale.new(code).language.code
        map.connect "#{langname}#{Radiant::Config['tags.results_page_url']}/:tag", :controller => 'site', :action => 'show_page', :url => Radiant::Config['tags.results_page_url'], :language => code
      end
    else
      map.connect "#{Radiant::Config['tags.results_page_url']}/:tag", :controller => 'site', :action => 'show_page', :url => Radiant::Config['tags.results_page_url']
    end
  end
  
  def activate
    raise "The Shards extension is required and must be loaded first!" unless defined?(Shards)
    Radiant::Config['tags.results_page_url'] = '/search/by-tag' unless Radiant::Config['tags.results_page_url']
    TagSearchPage
    Page.send :include, RadiusTags
    begin
      MetaTag
    rescue
      # dirty hack; need to get trough here to allow migrations to run..
    end
    Page.module_eval &TaggingMethods
    admin.page.edit.add :extended_metadata, 'tag_field'
  end
  
  def deactivate
  end
end