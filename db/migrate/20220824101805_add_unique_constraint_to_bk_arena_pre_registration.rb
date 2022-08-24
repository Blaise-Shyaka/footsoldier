class AddUniqueConstraintToBkArenaPreRegistration < ActiveRecord::Migration[6.1]
  def change
    add_index :bk_arena_pre_registrations, :id_number, unique: true
  end
end
