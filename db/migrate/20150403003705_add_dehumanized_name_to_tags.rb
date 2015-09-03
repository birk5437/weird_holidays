class AddDehumanizedNameToTags < ActiveRecord::Migration
  def change
    add_column :tags, :dehumanized_name, :string
  end
end
