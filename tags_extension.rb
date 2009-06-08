require_dependency 'application'
require File.dirname(__FILE__)+'/lib/tagging_methods'

class TagsExtension < Radiant::Extension
  version "1.4"
  description "This extension enhances the page model with tagging capabilities, tagging as in \"2.0\" and tagclouds."
  url "http://gorilla-webdesign.be"  
  
  DEFAULT_RESULTS_URL = '/search/by-tag'

  define_routes do |map|
    if Radiant::Config['tags.results_page_url'].blank?
      Radiant::Config['tags.results_page_url'] = TagsExtension::DEFAULT_RESULTS_URL if Radiant::Config['tags.results_page_url'].blank?
    end
    begin
      if defined?(SiteLanguage) && SiteLanguage.count > 0
        include Globalize
        SiteLanguage.codes.each do |code|
          langname = Locale.new(code).language.code
          map.connect "#{langname}#{Radiant::Config['tags.results_page_url']}/:tag", :controller => 'site', :action => 'show_page', :url => Radiant::Config['tags.results_page_url'], :language => code
        end
      else
        map.connect "#{Radiant::Config['tags.results_page_url']}/:tag", :controller => 'site', :action => 'show_page', :url => Radiant::Config['tags.results_page_url']
      end
    rescue
      # dirty hack; need to get trough here to allow migrations to run..
    end  
  end
  
  def activate
    raise "The Shards extension is required and must be loaded first!" unless defined?(admin.page)
    if Radiant::Config.table_exists?
      Radiant::Config['tags.results_page_url'] = TagsExtension::DEFAULT_RESULTS_URL unless Radiant::Config['tags.results_page_url']
      Radiant::Config['tags.complex_strings'] = 'false' unless Radiant::Config['tags.complex_strings']
    end
    TagSearchPage
    Page.send :include, RadiusTags
    begin
      MetaTag
    rescue
      # dirty hack; need to get trough here to allow migrations to run..
    end
    Page.module_eval &TaggingMethods
    SiteController.send :include, SiteControllerExtensions
    admin.page.edit.add :extended_metadata, 'tag_field'
    
    # HELP
    if admin.respond_to?(:help)
      admin.help.index.add :page_details, 'using_tags', :after => 'breadcrumbs'
    end
  end
  
  def deactivate
  end
end
