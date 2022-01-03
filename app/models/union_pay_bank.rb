require 'csv'

class UnionPayBank < ApplicationRecord
  belongs_to :user

  def self.to_csv
    attributes = %w{
                    created_at
                    bank_name 
                    atm_location 
                    upi_accepted 
                    why_test_not_allowed 
                    transaction_result
                    transaction_code
                    upi_decal_displayed_before_visit
                    upi_decal_displayed_after_visit
                    is_visa_or_mastercard_displayed
                    special_comments
                  }

    CSV.generate(headers: true) do |csv|
      csv << attributes

      all.each do |atm|
        csv << attributes.map{ |attr| atm.send(attr) }
      end
    end
  end
end
