class AddMerchantHasMultipleAcquirersToUnionPayMerchants < ActiveRecord::Migration[6.1]
  def change
    add_column :union_pay_merchants, :merchant_has_multiple_acquirers, :string, array: true, default: []
  end
end
