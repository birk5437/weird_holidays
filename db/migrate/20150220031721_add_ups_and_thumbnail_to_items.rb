class AddUpsAndThumbnailToItems < ActiveRecord::Migration
  def change
    add_column :items, :ups, :integer
    add_column :items, :thumbnail, :string
  end
end
