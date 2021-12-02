class UnionPay::ReportsController < UnionPayController
  def merchants
    @merchants = UnionPayMerchant.all
  end

  def banks
    @banks = UnionPayBank.all
  end
end