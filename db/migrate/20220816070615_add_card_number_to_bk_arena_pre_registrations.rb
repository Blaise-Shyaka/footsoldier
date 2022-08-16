class AddCardNumberToBkArenaPreRegistrations < ActiveRecord::Migration[6.1]
  def change
    add_column :bk_arena_pre_registrations, :card_first_four_digits, :string
    add_column :bk_arena_pre_registrations, :card_last_four_digits, :string
    add_column :bk_arena_pre_registrations, :issuing_branch, :string
  end
end
