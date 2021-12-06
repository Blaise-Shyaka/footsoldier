class Engen::ReportsController < EngenController
  def sales_per_day
    @sales = ChefWumujyi.group('created_at::date').order('created_at::date').sum(:fueled_value)
  end

  def sales_per_promoter
    @engen_promoters = User.includes(:chef_wumujyis).where(works_with_engen: true)
    @promoters_sales = []
    @engen_promoters.each do |promoter|
      @promoters_sales << {
        promoter_name: "#{promoter.first_name} #{promoter.last_name}",
        station: promoter.chef_wumujyis.first.service_station_name,
        sales: promoter.chef_wumujyis.group('created_at::date').order('created_at::date').sum(:fueled_value)
      }
    end
  end
end