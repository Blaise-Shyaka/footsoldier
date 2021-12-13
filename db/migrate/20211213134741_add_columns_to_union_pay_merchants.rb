class AddColumnsToUnionPayMerchants < ActiveRecord::Migration[6.1]
  def change
    add_column :union_pay_merchants, :acquirer_one, :string, default: ""
    add_column :union_pay_merchants, :acquirer_two, :string, default: ""
    add_column :union_pay_merchants, :acquirer_three, :string, default: ""
    add_column :union_pay_merchants, :acquirer_four, :string, default: ""
    add_column :union_pay_merchants, :acquirer_five, :string, default: ""
  end
end
