ActionController::Routing::Routes.draw do |map|
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
    else if defined?(VhostExtension)
      map.connect "#{Radiant::Config['tags.results_page_url']}/:tag", :controller => 'site', :action => 'show_page', :url => Radiant::Config['tags.results_page_url']
    end
      map.connect "#{Radiant::Config['tags.results_page_url']}/:tag", :controller => 'site', :action => 'show_page', :url => Radiant::Config['tags.results_page_url']
    end
  rescue
    # dirty hack; need to get trough here to allow migrations to run..
  end
end