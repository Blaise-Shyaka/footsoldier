class AddColumnToUnionPayMerchant < ActiveRecord::Migration[6.1]
  def change
    add_column :union_pay_merchants, :edited_by, :integer
  end
end
