class AddColumnsToUnionPayMerchant < ActiveRecord::Migration[6.1]
  def change
    add_column :union_pay_merchants, :contactless_code, :string, default: ""
    add_column :union_pay_merchants, :chip_in_pos_code, :string, default: ""
    add_column :union_pay_merchants, :swipe_code, :string, default: ""
  end
end
