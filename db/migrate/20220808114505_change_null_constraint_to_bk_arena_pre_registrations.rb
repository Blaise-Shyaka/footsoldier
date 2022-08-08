class ChangeNullConstraintToBkArenaPreRegistrations < ActiveRecord::Migration[6.1]
  def change
    change_column :bk_arena_pre_registrations, :spouse, :boolean, :null => true, default: false
    change_column :bk_arena_pre_registrations, :son_daughter, :boolean, :null => true, default: false
    change_column :bk_arena_pre_registrations, :parent, :boolean, :null => true, default: false
    change_column :bk_arena_pre_registrations, :brother_sister, :boolean, :null => true, default: false
  end
end
