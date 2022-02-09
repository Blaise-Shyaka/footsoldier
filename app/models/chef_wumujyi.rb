require 'csv'

class ChefWumujyi < ApplicationRecord
  belongs_to :user
  validates_length_of :telephone_number, minimum: 10, maximum: 10
  validates_length_of :plate_number, minimum: 5, maximum: 7

  def self.to_csv
    attributes = %w{created_at vehicle_type fueled_value customer_name telephone_number service_station_name}

    CSV.generate(headers: true) do |csv|
      csv << attributes

      all.each do |chef_wumujyi|
        csv << attributes.map{ |attr| chef_wumujyi.send(attr) }
      end
    end
  end
end
