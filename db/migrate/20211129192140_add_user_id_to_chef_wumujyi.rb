class AddUserIdToChefWumujyi < ActiveRecord::Migration[6.1]
  def change
    add_column :chef_wumujyis, :user_id, :integer
  end
end
