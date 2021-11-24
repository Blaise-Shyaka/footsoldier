class RemoveMerchantHasMultipleAcquirersFromUnionPayMerchants < ActiveRecord::Migration[6.1]
  def change
    remove_column :union_pay_merchants, :merchant_has_multiple_acquirers, :string
  end
end
