class AddSortOrderToItems < ActiveRecord::Migration
  def change
    add_column :items, :sort_order, :integer, null: false, default: 0
  end
end
