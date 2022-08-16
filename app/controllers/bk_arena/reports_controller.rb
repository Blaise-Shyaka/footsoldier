class BkArena::ReportsController < BkArenaController
  def general_report
    @bk_arena_clients = BkArenaPreRegistration.all
  end
end