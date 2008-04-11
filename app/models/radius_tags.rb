module RadiusTags
  include Radiant::Taggable
  include ActionView::Helpers::TextHelper
  
  class TagError < StandardError; end
  
  desc %{
    Find all pages with (a) certain tag(s), possibly in a certain scope.
    
    *Usage:*
    <pre><code><r:tagged with="shoes diesel" [scope="/fashion/cult-update"] [offset="number"] [limit="number"] [by="attribute"] [order="asc|desc"]>...</r:tagged></code></pre>
  }
  tag "tagged" do |tag|
    options = tagged_with_options(tag)
    result = []
    raise TagError, "`tagged' tag must contain a `with' attribute." unless (tag.attr['with'] || tag.locals.page.class_name = TagSearchPage)
    ttag = tag.attr['with'] || @request.parameters[:tag]
    if tag.attr['scope']
      scope = Page.find_by_url(tag.attr['scope'])
      return "The scope attribute must be a valid url to an existing page." if scope.class_name.eql?('FileNotFoundPage')
      # show only pages within scope
      Page.tagged_with(ttag, options).each do |page|
        next unless (page.ancestors.include?(scope) or page == scope)
        tag.locals.page = page
        result << tag.expand
      end
    else
      # show 'em all
      Page.tagged_with(ttag, options).each do |page|
        tag.locals.page = page
        result << tag.expand
      end
    end
    result
  end
  
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
  
  def tagged_with_options(tag)
    attr = tag.attr.symbolize_keys
    
    options = {}
    
    [:limit, :offset].each do |symbol|
      if number = attr[symbol]
        if number =~ /^\d{1,4}$/
          options[symbol] = number.to_i
        else
          raise TagError.new("`#{symbol}' attribute of `each' tag must be a positive number between 1 and 4 digits")
        end
      end
    end
    
    by = (attr[:by] || 'published_at').strip
    order = (attr[:order] || 'asc').strip
    order_string = ''
    if self.attributes.keys.include?(by)
      order_string << by
    else
      raise TagError.new("`by' attribute of `each' tag must be set to a valid field name")
    end
    if order =~ /^(asc|desc)$/i
      order_string << " #{$1.upcase}"
    else
      raise TagError.new(%{`order' attribute of `each' tag must be set to either "asc" or "desc"})
    end
    options[:order] = order_string
    
    status = (attr[:status] || 'published').downcase
    unless status == 'all'
      stat = Status[status]
      unless stat.nil?
        options[:conditions] = ["(virtual = ?) and (status_id = ?)", false, stat.id]
      else
        raise TagError.new(%{`status' attribute of `each' tag must be set to a valid status})
      end
    else
      options[:conditions] = ["virtual = ?", false]
    end
    options
  end
  
end