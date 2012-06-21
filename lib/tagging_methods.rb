TaggingMethods = Proc.new do
  
  def valid_with_tags?
    return (self.errors.empty? && valid_without_tags?)
  end
  alias_method_chain :valid?, :tags
  
  def save_with_tags!
    self.save_without_tags!
    # just skip the whole method if the tags string hasn't changed
    return self if @new_tags == tag_list
    
    # tags have changed, so we delete all taggings and re-create to preserve order
    taggings.clear
    
    @new_tags.to_s.split(MetaTag::DELIMITER).each do |tag|
      begin
        tag = MetaTag.find_or_initialize_by_name(tag.strip.squeeze(" "))
        meta_tags << tag unless meta_tags.include?(tag)
      rescue ActiveRecord::RecordInvalid => e
        errors.add_to_base("Tags can not contain special characters")
      rescue ActiveRecord::StatementInvalid => e
        # With SQLite3 - a duplicate tagging will result in the following message:
        # SQLite3::SQLException: SQL logic error or missing database: INSERT INTO taggings ("meta_tag_id", "taggable_type", "taggable_id") VALUES(11, 'Page', 74)
        # raise unless e.to_s =~ /duplicate/i
      end
    end
  end
  alias_method_chain :save!, :tags
  
  def meta_tags=(tags)
    @new_tags = tags
  end

  def ordered_meta_tags
    # HACK: need to order by tagging to preserve creation order, otherwise
    # list gets ordered by tag.id
    meta_tags.find(:all, :order => 'taggings.id')
  end

  def tag_list
    ordered_meta_tags.map(&:name).join(MetaTag::DELIMITER)
  end

   # 
   # Find all the objects tagged with the supplied list of tags
   # 
   # Usage : Model.tagged_with("ruby")
   #         Model.tagged_with("hello", "world")
   #         Model.tagged_with("hello", "world", :limit => 10)
   #
   def self.tagged_with(*tag_list)
     options = tag_list.extract_options!
     tag_list = parse_tags(tag_list)
   
     scope = scope(:find)
     options[:select] ||= "#{table_name}.*"
     options[:from] ||= "#{table_name}, meta_tags, taggings"
   
     sql  = "SELECT #{(scope && scope[:select]) || options[:select]} "
     sql << "FROM #{(scope && scope[:from]) || options[:from]} "

     add_joins!(sql, options[:joins], scope)
   
     sql << "WHERE #{table_name}.#{primary_key} = taggings.taggable_id "
     sql << "AND taggings.taggable_type = '#{ActiveRecord::Base.send(:class_name_of_active_record_descendant, self).to_s}' "
     sql << "AND taggings.meta_tag_id = meta_tags.id "
     sql << "AND pages.site_id = #{current_site.id} " if self.respond_to?(:current_site)
     
     sql << "AND (#{sanitize_sql(['meta_tags.name IN (?)', tag_list.map{|name| name.strip.squeeze(' ')}])}) "
     sql << "AND #{sanitize_sql(options[:conditions])} " if options[:conditions]
      
     columns = column_names.map do |column| 
       "#{table_name}.#{column}"
     end.join(", ")
      
     sql << "GROUP BY #{columns} "
     sql << "HAVING COUNT(taggings.meta_tag_id) = #{tag_list.size}"
   
     add_order!(sql, options[:order], scope)
     add_limit!(sql, options, scope)
     add_lock!(sql, options, scope)

   
     find_by_sql(sql)
   end
   
   def self.tagged_with_any(*tag_list)
     options = tag_list.extract_options!
     tag_list = parse_tags(tag_list)
   
     scope = scope(:find)
     options[:select] ||= "#{table_name}.*"
     options[:from] ||= "#{table_name}, meta_tags, taggings"
   
     sql  = "SELECT #{(scope && scope[:select]) || options[:select]} "
     sql << "FROM #{(scope && scope[:from]) || options[:from]} "

     add_joins!(sql, options[:joins], scope)
   
     sql << "WHERE #{table_name}.#{primary_key} = taggings.taggable_id "
     sql << "AND taggings.taggable_type = '#{ActiveRecord::Base.send(:class_name_of_active_record_descendant, self).to_s}' "
     sql << "AND taggings.meta_tag_id = meta_tags.id "
     sql << "AND pages.site_id = #{current_site.id} " if self.respond_to?(:current_site)
     
     sql << "AND ("
     sql << tag_list.inject([]) do |arr,name|
              arr << sanitize_sql(["meta_tags.name = ?", name.strip.squeeze(' ')])
            end.join(" OR ")
     sql << ") "
     
     
     sql << "AND #{sanitize_sql(options[:conditions])} " if options[:conditions]
      
     columns = column_names.map do |column| 
       "#{table_name}.#{column}"
     end.join(", ")
      
     sql << "GROUP BY #{columns} "
   
     add_order!(sql, options[:order], scope)
     add_limit!(sql, options, scope)
     add_lock!(sql, options, scope)
   
     find_by_sql(sql)
   end
 
   def self.parse_tags(tags)
     return [] if tags.blank?
     tags = Array(tags).first
     tags = tags.respond_to?(:flatten) ? tags.flatten : tags.split(MetaTag::DELIMITER)
     tags.map { |tag| tag.strip.squeeze(" ") }.flatten.compact.uniq
   end

end
