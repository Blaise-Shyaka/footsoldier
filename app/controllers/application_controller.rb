class ApplicationController < ActionController::Base
  def after_sign_in_path_for(resource_or_scope)
    if current_user.is_promoter && current_user.works_with_upi_merchants
      new_union_pay_merchant_path
    elsif current_user.is_promoter && current_user.works_with_upi_banks
      new_union_pay_bank_path
    elsif current_user.is_promoter && current_user.works_with_engen
      new_chef_wumujyi_path
    elsif current_user.is_upi_client
      union_pay_reports_banks_path
    elsif current_user.is_engen_client
      engen_reports_sales_per_day_path
    else
      user_path(@current_user.id)
    end
  end

  def after_sign_out_path_for(resource_or_scope)
    user_session_path
  end
end
