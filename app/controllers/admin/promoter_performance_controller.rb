class Admin::PromoterPerformanceController < AdminController

  before_action :authenticate_user

  def union_pay
    @union_pay_promoters = User.includes(:union_pay_banks, :union_pay_merchants).where(works_with_upi_merchants: true)
  end

  private

  def authenticate_user
    if current_user.nil?
      redirect_to new_user_session_path
    end
  end
end