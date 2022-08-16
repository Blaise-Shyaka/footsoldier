class AddBkAdminToBkArenaPreRegistrations < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :bk_arena_admin, :boolean, default: false
  end
end
