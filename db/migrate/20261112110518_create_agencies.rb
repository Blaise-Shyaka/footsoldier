class CreateAgencies < ActiveRecord::Migration[8.1]
  def change
    # The tenant root. Not tenant-owned itself: it has no agency_id and no row-level security.
    create_table :agencies do |t|
      t.string :slug, null: false
      t.string :name, null: false
      t.string :status, null: false, default: "active"
      t.string :data_region, null: false

      t.timestamps
    end

    add_index :agencies, :slug, unique: true
    add_check_constraint :agencies, "status IN ('active', 'suspended')", name: "agencies_status_check"
  end
end
