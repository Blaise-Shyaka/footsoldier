class Engen::ReportsController < EngenController
  before_action :verify_client_credentials

  def sales_per_day
    @sales = ChefWumujyi.group('created_at::date').order('created_at::date').sum(:fueled_value)
  end

  def sales_per_promoter
    @engen_promoters = User.includes(:chef_wumujyis).where(works_with_engen: true)
    @promoters_sales = []
    @engen_promoters.each do |promoter|
      @promoters_sales << {
        promoter_name: "#{promoter.first_name} #{promoter.last_name}",
        station: promoter.chef_wumujyis.length > 0 ? promoter.chef_wumujyis[0].service_station_name : "",
        sales: promoter.chef_wumujyis.length > 0 ? promoter.chef_wumujyis.group('created_at::date').order('created_at::date').sum(:fueled_value) : []
      }
    end
  end

  private

  def verify_client_credentials
    unless current_user.is_engen_client
      flash[:alert] = "Unauthorized! You must be from Engen to access this resource"
      redirect_to user_path(current_user)
    end
  end
end