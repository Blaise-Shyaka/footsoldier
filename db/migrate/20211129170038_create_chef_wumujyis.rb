class CreateChefWumujyis < ActiveRecord::Migration[6.1]
  def change
    create_table :chef_wumujyis do |t|
      t.string :vehicle_type
      t.integer :fueled_value
      t.string :plate_number
      t.string :customer_name
      t.string :telephone_number
      t.string :service_station_name

      t.timestamps
    end
  end
end
