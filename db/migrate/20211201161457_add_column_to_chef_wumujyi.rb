class AddColumnToChefWumujyi < ActiveRecord::Migration[6.1]
  def change
    add_column :chef_wumujyis, :coupon_number, :integer
  end
end
