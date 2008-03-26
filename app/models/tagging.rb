class Tagging < ActiveRecord::Base
  belongs_to :meta_tag 
  belongs_to :taggable, :polymorphic => true
  
  def before_destroy
    # if all the taggings for a particular <%= parent_association_name -%> are deleted, we want to 
    # delete the <%= parent_association_name -%> too
    meta_tag.destroy_without_callbacks if meta_tag.taggings.count < 2
  end    
end