class AddRedditIdToItems < ActiveRecord::Migration
  def change
    add_column :items, :reddit_id, :string
  end
end
