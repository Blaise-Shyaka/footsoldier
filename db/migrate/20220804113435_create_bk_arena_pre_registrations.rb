class CreateBkArenaPreRegistrations < ActiveRecord::Migration[6.1]
  def change
    create_table :bk_arena_pre_registrations do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :id_type, null: false
      t.string :id_number, null: false
      t.string :tel_no, null: false
      t.string :email, null: false, default: ""
      t.string :gender, null: false
      t.boolean :spouse, null: false
      t.boolean :son_daughter, null: false
      t.boolean :parent, null: false
      t.boolean :brother_sister, null: false
      t.string :other, default: ""
      t.string :province, null: false
      t.string :district, null: false
      t.string :sector, default: ""
      t.string :cell, default: ""
      t.string :village, default: ""
      t.string :preferred_branch, null: false
      t.integer :authorized_by
      t.integer :user_id

      t.timestamps
    end
  end
end
