module RadiusTags
  include Radiant::Taggable
  include ActionView::Helpers::TextHelper
  
  desc "Render a Tag cloud"
    
  tag "tag_cloud" do |tag|
    tag_cloud = MetaTag.cloud.sort
    output = "<ol class=\"tag_cloud\">"
    if tag_cloud.length > 0
    	build_tag_cloud(tag_cloud, %w(size1 size2 size3 size4 size5 size6 size7 size8 size9)) do |tag, cloud_class, amount|
    		output += "<li class=\"#{cloud_class}\"><span>#{pluralize(amount, 'page is', 'pages are')} tagged with </span><a href=\"#{tag_item_url(tag)}\" class=\"tag\">#{tag}</a></li>"
    	end
    else
    	return "<p>No tags found.</p>"
    end
    output += "</ol>"
  end
  
  desc "List the current page's tags"
  tag "tag_list" do |tag|
    output = []
    tag.locals.page.tag_list.split(" ").each {|t| output << "<a href=\"#{tag_item_url(t)}\" class=\"tag\">#{t}</a>"}
    output.join ", "
  end
  
  private
  
  def build_tag_cloud(tag_cloud, style_list)
    max, min = 0, 0
    tag_cloud.each do |tag|
      max = tag.popularity.to_i if tag.popularity.to_i > max
      min = tag.popularity.to_i if tag.popularity.to_i < min
    end
    
    divisor = ((max - min) / style_list.size) + 1

    tag_cloud.each do |tag|
      yield tag.name, style_list[(tag.popularity.to_i - min) / divisor], tag.popularity.to_i
    end
  end

  def tag_item_url(name)
    "#{Radiant::Config['tags.results_page_url']}?q=#{name}"
  end
  
  
end