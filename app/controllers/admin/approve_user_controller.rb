class Admin::ApproveUserController < AdminController
  before_action :verify_admin_credentials, only: :approve

  def approve
    @user = user_exists

    if @user.length.zero?
      flash.now[:alert] = "User doesn't exist!"
      return
    elsif @user.update(approve_user_params.except(:admin_secret_key))
      flash.now[:notice] = "User updated successfully!"
    else
      render :approve, flash.now[:alert] = "Failed to update user"
    end
  end

  private

  def approve_user_params
    params.require(:approve_user).permit(
      :email,
      :is_promoter,
      :works_with_engen,
      :works_with_upi_banks,
      :works_with_upi_merchants,
      :admin_secret_key
    )
  end

  def user_exists
    User.where(email: approve_user_params[:email])
  end

  def verify_admin_credentials
    unless ENV["admin_secret_key"] == approve_user_params[:admin_secret_key]
      flash[:alert] = "Failed! You must be an admin to do this operation"
      render :approve
    end
  end
end
