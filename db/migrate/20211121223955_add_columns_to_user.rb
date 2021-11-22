class AddColumnsToUser < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :is_promoter, :boolean, default: false
    add_column :users, :works_with_engen, :boolean, default: false
    add_column :users, :works_with_upi_merchants, :boolean, default: false
    add_column :users, :works_with_upi_banks, :boolean, default: false
  end
end
