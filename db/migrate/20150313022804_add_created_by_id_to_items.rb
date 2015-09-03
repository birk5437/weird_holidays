class AddCreatedByIdToItems < ActiveRecord::Migration
  def change
    add_column :items, :created_by_id, :integer
  end
end
