class MetaTag < ActiveRecord::Base

  if Radiant::Config['tags.complex_strings'] == 'true'
    delim = ";"
    re_format = /^[a-zA-Z0-9,\_\-\s\/()'.&]+$/
  else
    delim = " "
    re_format = /^[a-zA-Z0-9\_\-]+$/
  end
  DELIMITER = delim
    # how to separate tags in strings (you may
    # also need to change the validates_format_of parameters 
    # if you update this)

  # if speed becomes an issue, you could remove these validations 
  # and rescue the AR index errors instead
  validates_presence_of :name
  validates_uniqueness_of :name, :case_sensitive => false
  validates_format_of :name, :with => re_format, 
    :message => "can not contain special characters"
    
  has_many_polymorphs :taggables, 
    :from => [:pages], 
    :through => :taggings, 
    :dependent => :destroy,
    :skip_duplicates => false
  
  def after_save
    # if you allow editable tag names, you might want before_save instead 
    self.name = name.downcase.strip.squeeze(" ")
  end
 
  class << self
    def find_or_create_by_name!(name)
      find_by_name(name) || create!(:name => name)
    end

    def cloud(args = {})
      args = {:by => 'popularity', :order => 'desc', :limit => 5}.merge(args)

      find(:all, :select => 'meta_tags.*, count(*) as popularity',
      :limit => args[:limit],
      :joins => "JOIN taggings ON taggings.meta_tag_id = meta_tags.id",
      :conditions => args[:conditions],
      :group => "meta_tags.id, meta_tags.name",
      :order => order_string(args) )
    end

    def order_string(attr)
      by = (attr[:by]).strip
        order = (attr[:order]).strip
        order_string = ''
        if self.new.attributes.keys.dup.push("popularity").include?(by)
          order_string << by
        else
          raise TagError.new("`by' attribute of `each' tag must be set to a valid field name")
        end
        if order =~ /^(asc|desc)$/i
          order_string << " #{$1.upcase}"
        else
          raise TagError.new(%{`order' attribute of `each' tag must be set to either "asc" or "desc"})
        end

    end

  end
  
  def <=>(other)
    # To be able to sort an array of tags
    name <=> other.name
  end

end
