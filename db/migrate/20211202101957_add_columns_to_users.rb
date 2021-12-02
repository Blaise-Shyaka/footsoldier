class AddColumnsToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :is_upi_client, :boolean, default: false
    add_column :users, :is_engen_client, :boolean, default: false
  end
end
