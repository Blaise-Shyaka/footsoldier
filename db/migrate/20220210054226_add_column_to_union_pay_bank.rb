class AddColumnToUnionPayBank < ActiveRecord::Migration[6.1]
  def change
    add_column :union_pay_banks, :edited_by, :integer
  end
end
