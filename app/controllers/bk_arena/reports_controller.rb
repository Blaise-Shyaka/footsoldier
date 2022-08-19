class BkArena::ReportsController < BkArenaController
  def general_report
    @bk_arena_clients = BkArenaPreRegistration.all.order(updated_at: :desc)
    @promoters = User.all
    @total_pre_registrations = @bk_arena_clients.length
    @total_cards_issued = BkArenaPreRegistration.where.not(card_first_four_digits: nil).and(BkArenaPreRegistration.where.not(card_last_four_digits: nil)).length
  end
end