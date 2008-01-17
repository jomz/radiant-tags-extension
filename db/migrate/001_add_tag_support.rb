class AddTagSupport < ActiveRecord::Migration
  def self.up
    # removes any existing meta_tags & taggins tables !!
    # self.down
    
    create_table :meta_tags do |t|
      t.column :name, :string, :null => false
    end
    add_index :meta_tags, :name, :unique => true

    create_table :taggings do |t|
      t.column :meta_tag_id, :integer, :null => false
      t.column :taggable_id, :integer, :null => false
      t.column :taggable_type, :string, :null => false
    end
    add_index :taggings, [:meta_tag_id, :taggable_id, :taggable_type], :unique => true
  end

  def self.down
    drop_table :meta_tags
    drop_table :taggings
  end
end