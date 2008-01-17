class ActiveRecord::Base

  def tag_with tags
    # just skip the whole method if the tags string hasn't changed
    return if tags == tag_list
    # do we need to delete any tags?
    tags_to_delete = tag_list.split(' ') - tags.split(' ')
    # tags_to_delete.select{|t| meta_tags.delete(MetaTag.find_by_name(t))}

    tags.split(" ").each do |tag|
      begin
        MetaTag.find_or_create_by_name(tag).taggables << self
      rescue ActiveRecord::StatementInvalid => e
        raise unless e.to_s =~ /duplicate/i
      end
    end
    
  end

  def tag_list
    meta_tags.map(&:name).join(' ')
  end
  
  alias :meta_tags= :tag_with

end