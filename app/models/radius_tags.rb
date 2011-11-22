module RadiusTags
  include Radiant::Taggable
  include ActionView::Helpers::TextHelper
  
  class TagError < StandardError; end
  
  desc %{
    Expands if a <pre><r:tagged with="" /></pre> call would return items. Takes the same options as the 'tagged' tag.
    The <pre><r:unless_tagged with="" /></pre> is also available.
  }
  tag "if_tagged" do |tag|
    if tag.attr["with"]
      tag.locals.tagged_results = find_with_tag_options(tag)
      tag.expand unless tag.locals.tagged_results.empty?
    else
      tag.expand unless tag.locals.page.tag_list.empty?
    end
  end
  tag "unless_tagged" do |tag|
    if tag.attr["with"]
      tag.expand if find_with_tag_options(tag).empty?
    else
      tag.expand if tag.locals.page.tag_list.empty?
    end
  end
  
  desc %{
    Find all pages with certain tags, within in an optional scope. Additionally, you may set with_any to true to select pages that have any of the listed tags (opposed to all listed tags which is the provided default).
    
    *Usage:*
    <pre><code><r:tagged with="shoes diesel" [scope="/fashion/cult-update"] [with_any="true"] [offset="number"] [limit="number"] [by="attribute"] [order="asc|desc"]>...</r:tagged></code></pre>
  }
  tag "tagged" do |tag|
    unless tag.locals.tagged_results.nil? # We're inside an r:if_tagged, so results are already available;
      results = tag.locals.tagged_results
    else
      results = find_with_tag_options(tag)
    end
    output = []
    results.each do |page|
      tag.locals.page = page
      output << tag.expand
    end
    output
  end
  
  desc %{
    Find all pages related to the current page, based on all or any of the current page's tags. A scope attribute may be given to limit results to a certain site area.
    
    *Usage:*
    <pre><code><r:related_by_tags [scope="/fashion/cult-update"] [offset="number"] [limit="number"] [by="attribute"] [order="asc|desc"]>...</r:related_by_tags></code></pre>
  }
  tag "related_by_tags" do |tag|
    tag.attr["with"] = tag.locals.page.tag_list.split(MetaTag::DELIMITER)
    tag.attr["with_any"] = true
    tag.attr["exclude_id"] = tag.locals.page.id
    results = find_with_tag_options(tag)
    return false if results.size < 1
    output = []
    first = true
    results.each do |page|
      tag.locals.page = page
      tag.locals.first = first
      output << tag.expand
      first = false
    end
    output
  end
  
  tag "if_has_related_by_tags" do |tag|
    tag.attr["with"] = tag.locals.page.tag_list.split(MetaTag::DELIMITER)
    tag.attr["with_any"] = true
    tag.attr["exclude_id"] = tag.locals.page.id
    results = find_with_tag_options(tag)
    results -= [tag.locals.page]
    tag.expand if results.size > 0
  end
  
  tag "related_by_tags:if_first" do |tag|
    tag.expand if tag.locals.first
  end
  
  desc %{
    Render a Tag cloud
    The results_page attribute will default to #{Radiant::Config['tags.results_page_url']}
    
    *Usage:*
    <pre><code><r:tag_cloud [limit="number"] [results_page="/some/url"] [scope="/some/url"]/></code></pre>
  }
  tag "tag_cloud" do |tag|
    tag_cloud = MetaTag.cloud(:limit => tag.attr['limit'] || 5).sort
    tag_cloud = filter_tags_to_url_scope(tag_cloud, tag.attr['scope']) unless tag.attr['scope'].nil?
    
    results_page = tag.attr['results_page'] || Radiant::Config['tags.results_page_url']
    output = "<ol class=\"tag_cloud\">"
    if tag_cloud.length > 0
    	build_tag_cloud(tag_cloud, %w(size1 size2 size3 size4 size5 size6 size7 size8 size9)) do |tag, cloud_class, amount|
    		output += "<li class=\"#{cloud_class}\"><span>#{pluralize(amount, 'page is', 'pages are')} tagged with </span><a href=\"#{results_page}/#{url_encode(tag)}\" class=\"tag\">#{tag}</a></li>"
    	end
    else
    	return I18n.t('tags_extension.no_tags_found')
    end
    output += "</ol>"
  end

  desc %{
    Render a Tag cloud with div-tags
    The results_page attribute will default to #{Radiant::Config['tags.results_page_url']}
    
    *Usage:*
    <pre><code><r:tag_cloud_div [limit="number"] [results_page="/some/url"] [scope="/some/url"]/></code></pre>
  }
  tag "tag_cloud_div" do |tag|
    tag_cloud = MetaTag.cloud(:limit => tag.attr['limit'] || 10).sort
    tag_cloud = filter_tags_to_url_scope(tag_cloud, tag.attr['scope']) unless tag.attr['scope'].nil?
    
    results_page = tag.attr['results_page'] || Radiant::Config['tags.results_page_url']
    output = "<div class=\"tag_cloud\">"
    if tag_cloud.length > 0
    	build_tag_cloud(tag_cloud, %w(size1 size2 size3 size4 size5 size6 size7 size8 size9)) do |tag, cloud_class, amount|
    		output += "<div class=\"#{cloud_class}\"><a href=\"#{results_page}/#{url_encode(tag)}\" class=\"tag\">#{tag}</a></div>\n"
    	end
    else
    	return I18n.t('tags_extension.no_tags_found')
    end
    output += "</div>"
  end
 
  desc %{
    Render a Tag list, more for 'categories'-ish usage, i.e.: Cats (2) Logs (1) ...
    The results_page attribute will default to #{Radiant::Config['tags.results_page_url']}
    
    *Usage:*
    <pre><code><r:tag_cloud_list [results_page="/some/url"] [scope="/some/url"]/></code></pre>
  }
  tag "tag_cloud_list" do |tag|
    tag_cloud = MetaTag.cloud({:limit => 100}).sort
    tag_cloud = filter_tags_to_url_scope(tag_cloud, tag.attr['scope']) unless tag.attr['scope'].nil?
    
    results_page = tag.attr['results_page'] || Radiant::Config['tags.results_page_url']
    output = "<ul class=\"tag_list\">"
    if tag_cloud.length > 0
        build_tag_cloud(tag_cloud, %w(size1 size2 size3 size4 size5 size6 size7 size8 size9)) do |tag, cloud_class, amount|
          output += "<li class=\"#{cloud_class}\"><a href=\"#{results_page}/#{url_encode(tag)}\" class=\"tag\">#{tag} (#{amount})</a></li>"
        end
    else
        return I18n.t('tags_extension.no_tags_found')
    end
    output += "</ul>"
  end
 
  desc "List the current page's tags"
  tag "tag_list" do |tag|
    results_page = tag.attr['results_page'] || Radiant::Config['tags.results_page_url']
    output = []
    tag.locals.page.tag_list.split(MetaTag::DELIMITER).each {|t| output << "<a href=\"#{results_page}/#{t}\" class=\"tag\">#{t}</a>"}
    output.join ", "
  end
  
  desc "List the current page's tagsi as technorati tags. this should be included in the body of a post or in your rss feed"
  tag "tag_list_technorati" do |tag|
    output = []
    tag.locals.page.tag_list.split(MetaTag::DELIMITER).each {|t| output << "<a href=\"http://technorati.com/tag/#{ t.split(" ").join("+")}\" rel=\"tag\">#{t}</a>"}
    output.join ", "
  end
  
  tag "tags" do |tag|
    tag.expand
  end
  
  desc %{
    Cycles through the tags of the current page
    Accepts an optional @limit@ attributem default is to show everything.
    
    Usage: <pre><code><r:tags:each [limit="4"]>...</r:tags:each></code></pre>
  }
  tag "tags:each" do |tag|
    selected_tags = tag.locals.page.ordered_meta_tags
    if tag.attr['limit']
      selected_tags = selected_tags.first(tag.attr['limit'].to_i)
    end
    selected_tags.enum_with_index.collect do |meta_tag, index|
      tag.locals.meta_tag = meta_tag
      tag.locals.is_first_meta_tag = index == 0
      tag.locals.is_last_meta_tag = index == selected_tags.length - 1
      tag.expand
    end
  end
  
  tag "tags:each:name" do |tag|
    tag.locals.meta_tag.name
  end
  
  tag "tags:each:link" do |tag|
    results_page = tag.attr['results_page'] || Radiant::Config['tags.results_page_url']
    name = tag.locals.meta_tag.name
    return "<a href=\"#{results_page}/#{url_encode(name)}\" class=\"tag\">#{name}</a>"
  end
  
  tag 'tags:each:if_first' do |tag|
    tag.expand if tag.locals.is_first_meta_tag
  end

  tag 'tags:each:unless_first' do |tag|
    tag.expand unless tag.locals.is_first_meta_tag
  end

  tag 'tags:each:if_last' do |tag|
    tag.expand if tag.locals.is_last_meta_tag
  end

  tag 'tags:each:unless_last' do |tag|
    tag.expand unless tag.locals.is_last_meta_tag
  end

  desc "Set the scope for all tags in the database"
  tag "all_tags" do |tag|
    tag.expand
  end
  
  desc %{
    Iterates through each tag and allows you to specify the order: by popularity or by name.
    The default is by name. You may also limit the search; the default is 5 results.
    
    Usage: <pre><code><r:all_tags:each [order="asc|desc"] [by="name|popularity"] limit="5">...</r:all_tags:each></code></pre>
  }
  tag "all_tags:each" do |tag|
    by = (tag.attr['by'] || 'name').strip
    order = (tag.attr['order'] || 'asc').strip
    limit = tag.attr['limit'] || '5'
    begin
      all_tags = MetaTag.cloud(:limit => limit, :order => order, :by => by)
    rescue => e
      raise TagError, "all_tags:each: "+e.message
    end
    used_tags = all_tags.reject { |t| t.pages.empty? }
    used_tags.collect do |t|
      tag.locals.meta_tag = t
      tag.expand
    end.join
  end
  
  desc "Renders the tag's name"
  tag "all_tags:each:name" do |tag|
    tag.locals.meta_tag.name
  end
  
  tag "all_tags:each:link" do |tag|
    results_page = tag.attr['results_page'] || Radiant::Config['tags.results_page_url']
    name = tag.locals.meta_tag.name
    "<a href=\"#{results_page}/#{url_encode(name)}\" class=\"tag\">#{name}</a>"
  end

  tag "all_tags:each:popularity" do |tag|
    (tag.locals.meta_tag.respond_to?(:popularity)) ? tag.locals.meta_tag.popularity : ""
  end

  tag "all_tags:each:url" do |tag|
    results_page = tag.attr['results_page'] || Radiant::Config['tags.results_page_url']
    name = tag.locals.meta_tag.name
    "#{results_page}/#{url_encode(name)}"
  end
  
  desc "Set the scope for the tag's pages"
  tag "all_tags:each:pages" do |tag|
    tag.expand
  end
  
  desc "Iterates through each page"
  tag "all_tags:each:pages:each" do |tag|
    result = []
    tag.locals.meta_tag.taggables.each do |taggable|
      if taggable.is_a?(Page)
        tag.locals.page = taggable
        result << tag.expand
      end
    end
    result
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
    "#{Radiant::Config['tags.results_page_url']}/#{name}"
  end
  
  def find_with_tag_options(tag)
    options = tagged_with_options(tag)
    with_any = tag.attr['with_any'] || false
    scope_attr = tag.attr['scope'] || '/'
    results = []
    raise TagError, "`tagged' tag must contain a `with' attribute." unless (tag.attr['with'] || tag.locals.page.class_name = TagSearchPage)
    ttag = tag.attr['with'] || @request.parameters[:tag]
    
    scope_path = scope_attr == 'current_page' ? @request.request_uri : scope_attr
    scope = Page.find_by_path scope_path
    return "The scope attribute must be a valid url to an existing page." if scope.nil? || scope.class_name.eql?('FileNotFoundPage')
    
    if with_any
      Page.tagged_with_any(ttag, options).each do |page|
          next unless (page.ancestors.include?(scope) or page == scope)
          results << page
      end
    else
      Page.tagged_with(ttag, options).each do |page|
          next unless (page.ancestors.include?(scope) or page == scope)
          results << page
      end
    end
    results
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
    exclude = attr[:exclude_id] ? "AND pages.id != #{attr[:exclude_id]}" : ""
    
    unless status == 'all'
      stat = Status[status]
      unless stat.nil?
        options[:conditions] = ["(virtual = ?) and (status_id = ?) #{exclude} and (published_at <= ?)", false, stat.id, Time.current]
      else
        raise TagError.new(%{`status' attribute of `each' tag must be set to a valid status})
      end
    else
      options[:conditions] = ["virtual = ? #{exclude}", false]
    end
    options
  end

  def filter_tags_to_url_scope(tags, scope)
    new_tags = []
    tags.each do |t|
      catch :record_found do # using fancy ballsports stuff to avoid unnecessary db calls (by calling each page, ànd by calling page.url)
        t.pages.each do |p|
          (new_tags << t; throw :record_found) if p.url.include?(scope)
        end
      end
    end
    new_tags
  end
end
