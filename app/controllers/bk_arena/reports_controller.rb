class BkArena::ReportsController < BkArenaController
  before_action :authenticate_user
  before_action :verify_credentials

  def general_report
    @bk_arena_clients = BkArenaPreRegistration.all.order(updated_at: :desc)
    @promoters = User.all
    @total_pre_registrations = @bk_arena_clients.length
    @total_cards_issued = BkArenaPreRegistration.where.not(card_first_four_digits: nil).and(BkArenaPreRegistration.where.not(card_last_four_digits: nil)).length
  end

  def individual_performance
    @promoters = User.where(works_with_bk_arena: true)
    @preregistrations = BkArenaPreRegistration.all
  end

  private

  def verify_credentials
    unless current_user.bk_arena_admin
      flash[:alert] = "Ooooops ... You don't have access to this page"
      redirect_to user_path(current_user)
    end
  end

  def authenticate_user
    if current_user.nil?
      redirect_to new_user_session_path
    end
  end
end