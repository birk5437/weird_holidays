class ItemsAreOnlyTitleDatesAndDescription < ActiveRecord::Migration
  def change
    remove_column :items, :url, :string
    remove_column :items, :price, :decimal
    remove_column :items, :ups, :integer
    remove_column :items, :thumbnail, :string
    remove_column :items, :reddit_id, :integer
    remove_column :items, :sort_order, :integer

    add_column :items, :start_date, :datetime
    add_column :items, :end_date, :datetime
  end
end
