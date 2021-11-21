class AddUserIdToUnionPayMerchants < ActiveRecord::Migration[6.1]
  def change
    add_column :union_pay_merchants, :user_id, :integer
  end
end
