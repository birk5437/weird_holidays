class AddSuperuserFlagToUsers < ActiveRecord::Migration
  def change
    add_column :users, :superuser, :boolean, null: false, default: false
  end
end
