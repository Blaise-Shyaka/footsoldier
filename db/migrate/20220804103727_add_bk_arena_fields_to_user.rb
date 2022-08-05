class AddBkArenaFieldsToUser < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :works_with_bk_arena, :boolean, default: false
    add_column :users, :is_bk_arena_client, :boolean, default: false
    add_column :users, :is_bk_arena_agent, :boolean, default: false
    add_column :users, :bk_arena_branch, :string, default: ""
  end
end
