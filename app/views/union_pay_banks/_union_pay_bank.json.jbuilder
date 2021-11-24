json.extract! union_pay_bank, :id, :bank_name, :atm_location, :upi_accepted, :why_test_not_allowed, :transaction_result, :transaction_code, :upi_decal_displayed_before_visit, :upi_decal_displayed_after_visit, :is_visa_or_mastercard_displayed, :special_comments, :user_id, :created_at, :updated_at
json.url union_pay_bank_url(union_pay_bank, format: :json)
