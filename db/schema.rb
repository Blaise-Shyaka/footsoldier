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

ActiveRecord::Schema.define(version: 2021_11_20_145154) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "union_pay_merchants", force: :cascade do |t|
    t.string "merchant_name", default: "", null: false
    t.string "address", default: "", null: false
    t.string "merchant_category", default: "", null: false
    t.string "merchant_accept_international_payment", default: "", null: false
    t.string "merchant_has_multiple_acquirers", default: "", null: false
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
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

end
