class TagSearchPage < Page

  attr_accessor :requested_tag
  #### Tags ####
  desc %{    The namespace for all search tags.}
  tag 'search' do |tag|
    tag.expand
  end

  desc %{    Renders the passed query.}
  tag 'search:query' do |tag|
    CGI.escapeHTML(requested_tag)
  end
  
  desc %{    Renders the contained block if no results were returned.}
  tag 'search:empty' do |tag|
    if found_tags.blank?
      tag.expand
    end
  end
  
  desc %{    Renders the contained block if results were returned.}
  tag 'search:results' do |tag|
    unless found_tags.blank?
      tag.expand
    end
  end

  desc %{    <r:search:results:each [sort_by="id"] [order="asc"]/>
    Renders the contained block for each result page.  The context
    inside the tag refers to the found page. The optional sort_by and order attributes
    specify how the results are sorted}
  tag 'search:results:each' do |tag|
    # Ordering in Ruby because we already fetched our resultset before
    tags = found_tags
    tags = tags.sort_by(&tag.attr['sort_by'].to_sym)  if tag.attr['sort_by']
    tags = tags.reverse                               if tag.attr['order'].to_s =~ /desc/i
    
    returning String.new do |content|
      tags.each do |page|
        tag.locals.page = page
        content << tag.expand
      end
    end
  end
  
  desc %{    <r:truncate_and_strip [length="100"] />
    Truncates and strips all HTML tags from the content of the contained block.  
    Useful for displaying a snippet of a found page.  The optional `length' attribute
    specifies how many characters to truncate to.}
  tag 'truncate_and_strip' do |tag|
    tag.attr['length'] ||= 100
    length = tag.attr['length'].to_i
    helper = ActionView::Base.new
    helper.truncate(helper.strip_tags(tag.expand).gsub(/\s+/," "), length)
  end
  
  #### "Behavior" methods ####
  def cache?
    true
  end
  
  def found_tags
    return @found_tags if @found_tags
    return []          if requested_tag.blank?
    
    @found_tags = Page.tagged_with(requested_tag).delete_if { |p| !p.published? }
  end
  
  def render
    self.requested_tag = @request.parameters[:tag]
    self.title = "Tagged with #{requested_tag}" if requested_tag
    
    super
  end
  
end