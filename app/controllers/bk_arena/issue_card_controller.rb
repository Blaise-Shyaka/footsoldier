class BkArena::IssueCardController < BkArenaController
  before_action :authenticate_user
  before_action :verify_promoter_credentials

  def search_client
    @bk_arena_pre_registrations = BkArenaPreRegistration.all
  end

  def search
    @bk_arena_pre_registrations = BkArenaPreRegistration.where("id_number LIKE ? OR tel_no LIKE ?", "%#{search_client_params[:query]}%", "%#{search_client_params[:query]}%")
  end

  def edit
    @bk_arena_pre_registration = BkArenaPreRegistration.find(params[:id])
  end

  def update
    respond_to do |format|
      if @bk_arena_pre_registration.update(bk_arena_pre_registration_params)
        format.html { redirect_to @bk_arena_pre_registration, notice: "Bk arena pre registration was successfully updated." }
        format.json { render :show, status: :ok, location: @bk_arena_pre_registration }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @bk_arena_pre_registration.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def search_client_params
    params.require(:search).permit(:query) || {}
  end

  def verify_promoter_credentials
    unless current_user.is_promoter && current_user.is_bk_arena_agent
      flash[:alert] = "Ooooops ... You don't work as a BK Arena Agent"
      redirect_to user_path(current_user)
    end
  end

  def authenticate_user
    if current_user.nil?
      redirect_to new_user_session_path
    end
  end

  def bk_arena_pre_registration_params
    params.require(:bk_arena_pre_registration).permit(
    :first_name,
    :last_name,
    :id_type,
    :id_number,
    :tel_no,
    :email,
    :gender,
    :spouse,
    :son_daughter,
    :parent,
    :brother_sister,
    :other,
    :province,
    :district,
    :sector,
    :cell,
    :village,
    :preferred_branch,
    :authorized_by,
    :issuing_branch,
    :card_first_four_digits,
    :card_last_four_digits
    )
  end
end