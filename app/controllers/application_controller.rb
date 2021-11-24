class ApplicationController < ActionController::Base
  def after_sign_in_path_for(resource_or_scope)
    if current_user.is_promoter && current_user.works_with_upi_merchants
      new_union_pay_merchant_path
    elsif current_user.is_promoter && current_user.works_with_upi_banks
      new_union_pay_bank_path
    else
      user_path(@user)
    end
  end

  def after_sign_out_path_for(resource_or_scope)
    user_session_path
  end
end
