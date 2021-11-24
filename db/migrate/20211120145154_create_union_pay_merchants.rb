class CreateUnionPayMerchants < ActiveRecord::Migration[6.1]
  def change
    create_table :union_pay_merchants do |t|
      t.string :merchant_name, null: false, default: ""
      t.string :address, null: false, default: ""
      t.string :merchant_category, null: false, default: ""
      t.string :merchant_accept_international_payment, null: false, default: ""
      t.string :merchant_has_multiple_acquirers, null: false, default: ""
      t.string :contactless_upi_accepted, null: false, default: ""
      t.string :contactless_why_upi_not_accepted, null: false, default: ""
      t.string :contactless_purchase_transaction_result, null: false, default: ""
      t.string :contactless_other_card_schemes_accepted, null: false, default: ""
      t.string :contactless_test_scenario, null: false, default: ""

      t.string :chip_in_pos_upi_accepted, null: false, default: ""
      t.string :chip_in_pos_why_upi_not_accepted, null: false, default: ""
      t.string :chip_in_pos_purchase_transaction_result, null: false, default: ""
      t.string :chip_in_pos_other_card_schemes_accepted, null: false, default: ""
      t.string :chip_in_pos_test_scenario, null: false, default: ""

      t.string :swipe_upi_accepted, null: false, default: ""
      t.string :swipe_why_upi_not_accepted, null: false, default: ""
      t.string :swipe_purchase_transaction_result, null: false, default: ""
      t.string :swipe_other_card_schemes_accepted, null: false, default: ""
      t.string :swipe_test_scenario, null: false, default: ""

      t.string :upi_decal_displayed_before_visit, null: false, default: ""
      t.string :upi_decal_displayed_after_visit, null: false, default: ""
      t.string :is_visa_or_mastercard_displayed, null: false, default: ""
      t.string :is_contactless_mark_shown_upi_single_decal, null: false, default: ""
      t.string :is_visa_or_mastercard_contactless_mark_shown_on_single_decal, null: false, default: ""
      t.string :is_contactless_mark_shown_on_integrated_decal, null: false, default: ""
      t.text :special_comments, null: false, default: ""

      t.timestamps
    end
  end
end
