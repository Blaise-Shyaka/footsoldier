class UnionPay::ReportsController < UnionPayController
  before_action :verify_client_credentials
  
  def merchants
    @merchants = UnionPayMerchant.all
  end

  def banks
    @banks = UnionPayBank.all
  end

  def verify_client_credentials
    unless current_user.is_upi_client
      flash[:alert] = "Unauthorized! You must be from UPI to access this resource"
      redirect_to user_path(current_user)
    end
  end
end