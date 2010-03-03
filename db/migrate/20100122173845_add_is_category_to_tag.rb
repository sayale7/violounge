class AddIsCategoryToTag < ActiveRecord::Migration
  def self.up
    add_column :tags, :is_category, :boolean
  end

  def self.down
    remove_column :tags, :is_category
  end
end
