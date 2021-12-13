# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_12_13_134741) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "chef_wumujyis", force: :cascade do |t|
    t.string "vehicle_type"
    t.integer "fueled_value"
    t.string "plate_number"
    t.string "customer_name"
    t.string "telephone_number"
    t.string "service_station_name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "user_id"
    t.integer "coupon_number"
  end

  create_table "union_pay_banks", force: :cascade do |t|
    t.string "bank_name", default: "", null: false
    t.string "atm_location", default: "", null: false
    t.string "upi_accepted", default: "", null: false
    t.text "why_test_not_allowed", default: "", null: false
    t.string "transaction_result", default: "", null: false
    t.string "transaction_code", default: "", null: false
    t.string "upi_decal_displayed_before_visit", default: "", null: false
    t.string "upi_decal_displayed_after_visit", default: "", null: false
    t.string "is_visa_or_mastercard_displayed", default: "", null: false
    t.string "special_comments", default: "", null: false
    t.integer "user_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "union_pay_merchants", force: :cascade do |t|
    t.string "merchant_name", default: "", null: false
    t.string "address", default: "", null: false
    t.string "merchant_category", default: "", null: false
    t.string "merchant_accept_international_payment", default: "", null: false
    t.string "contactless_upi_accepted", default: "", null: false
    t.string "contactless_why_upi_not_accepted", default: "", null: false
    t.string "contactless_purchase_transaction_result", default: "", null: false
    t.string "contactless_other_card_schemes_accepted", default: "", null: false
    t.string "contactless_test_scenario", default: "", null: false
    t.string "chip_in_pos_upi_accepted", default: "", null: false
    t.string "chip_in_pos_why_upi_not_accepted", default: "", null: false
    t.string "chip_in_pos_purchase_transaction_result", default: "", null: false
    t.string "chip_in_pos_other_card_schemes_accepted", default: "", null: false
    t.string "chip_in_pos_test_scenario", default: "", null: false
    t.string "swipe_upi_accepted", default: "", null: false
    t.string "swipe_why_upi_not_accepted", default: "", null: false
    t.string "swipe_purchase_transaction_result", default: "", null: false
    t.string "swipe_other_card_schemes_accepted", default: "", null: false
    t.string "swipe_test_scenario", default: "", null: false
    t.string "upi_decal_displayed_before_visit", default: "", null: false
    t.string "upi_decal_displayed_after_visit", default: "", null: false
    t.string "is_visa_or_mastercard_displayed", default: "", null: false
    t.string "is_contactless_mark_shown_upi_single_decal", default: "", null: false
    t.string "is_visa_or_mastercard_contactless_mark_shown_on_single_decal", default: "", null: false
    t.string "is_contactless_mark_shown_on_integrated_decal", default: "", null: false
    t.text "special_comments", default: "", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "user_id"
    t.string "contactless_code", default: ""
    t.string "chip_in_pos_code", default: ""
    t.string "swipe_code", default: ""
    t.string "merchant_has_multiple_acquirers", default: [], array: true
    t.string "acquirer_one", default: ""
    t.string "acquirer_two", default: ""
    t.string "acquirer_three", default: ""
    t.string "acquirer_four", default: ""
    t.string "acquirer_five", default: ""
  end

  create_table "users", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "telephone_number", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "is_promoter", default: false
    t.boolean "works_with_engen", default: false
    t.boolean "works_with_upi_merchants", default: false
    t.boolean "works_with_upi_banks", default: false
    t.boolean "is_upi_client", default: false
    t.boolean "is_engen_client", default: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

end
