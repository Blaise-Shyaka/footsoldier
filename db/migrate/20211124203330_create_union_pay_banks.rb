class CreateUnionPayBanks < ActiveRecord::Migration[6.1]
  def change
    create_table :union_pay_banks do |t|
      t.string :bank_name, null: false, default: ""
      t.string :atm_location, null: false, default: ""
      t.string :upi_accepted, null: false, default: ""
      t.text :why_test_not_allowed, null: false, default: ""
      t.string :transaction_result, null: false, default: ""
      t.string :transaction_code, null: false, default: ""
      t.string :upi_decal_displayed_before_visit, null: false, default: ""
      t.string :upi_decal_displayed_after_visit, null: false, default: ""
      t.string :is_visa_or_mastercard_displayed, null: false, default: ""
      t.string :special_comments, null: false, default: ""
      t.integer :user_id

      t.timestamps
    end
  end
end
