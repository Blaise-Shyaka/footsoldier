class ApplicationController < ActionController::Base
  def after_sign_in_path_for(resource_or_scope)
    new_union_pay_merchant_path
  end

  def after_sign_out_path_for(resource_or_scope)
    user_session_path
  end
end
