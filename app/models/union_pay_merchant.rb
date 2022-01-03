require 'csv'

class UnionPayMerchant < ApplicationRecord
  belongs_to :user

  def self.to_csv
    attributes = %w{
                    created_at
                    merchant_name 
                    address 
                    merchant_category 
                    merchant_accept_international_payment 
                    chip_in_pos_upi_accepted
                    chip_in_pos_why_upi_not_accepted
                    chip_in_pos_purchase_transaction_result
                    chip_in_pos_other_card_schemes_accepted
                    upi_decal_displayed_before_visit
                    upi_decal_displayed_after_visit
                    acquirer_one
                    acquirer_two
                    acquirer_three
                    acquirer_four
                    acquirer_five
                    special_comments
                  }

    CSV.generate(headers: true) do |csv|
      csv << attributes

      all.each do |merchant|
        csv << attributes.map{ |attr| merchant.send(attr) }
      end
    end
  end
end
