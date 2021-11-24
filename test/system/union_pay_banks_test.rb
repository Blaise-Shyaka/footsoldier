require "application_system_test_case"

class UnionPayBanksTest < ApplicationSystemTestCase
  setup do
    @union_pay_bank = union_pay_banks(:one)
  end

  test "visiting the index" do
    visit union_pay_banks_url
    assert_selector "h1", text: "Union Pay Banks"
  end

  test "creating a Union pay bank" do
    visit union_pay_banks_url
    click_on "New Union Pay Bank"

    fill_in "Atm location", with: @union_pay_bank.atm_location
    fill_in "Bank name", with: @union_pay_bank.bank_name
    fill_in "Is visa or mastercard displayed", with: @union_pay_bank.is_visa_or_mastercard_displayed
    fill_in "Special comments", with: @union_pay_bank.special_comments
    fill_in "Transaction code", with: @union_pay_bank.transaction_code
    fill_in "Transaction result", with: @union_pay_bank.transaction_result
    fill_in "Upi accepted", with: @union_pay_bank.upi_accepted
    fill_in "Upi decal displayed after visit", with: @union_pay_bank.upi_decal_displayed_after_visit
    fill_in "Upi decal displayed before visit", with: @union_pay_bank.upi_decal_displayed_before_visit
    fill_in "User", with: @union_pay_bank.user_id
    fill_in "Why test not allowed", with: @union_pay_bank.why_test_not_allowed
    click_on "Create Union pay bank"

    assert_text "Union pay bank was successfully created"
    click_on "Back"
  end

  test "updating a Union pay bank" do
    visit union_pay_banks_url
    click_on "Edit", match: :first

    fill_in "Atm location", with: @union_pay_bank.atm_location
    fill_in "Bank name", with: @union_pay_bank.bank_name
    fill_in "Is visa or mastercard displayed", with: @union_pay_bank.is_visa_or_mastercard_displayed
    fill_in "Special comments", with: @union_pay_bank.special_comments
    fill_in "Transaction code", with: @union_pay_bank.transaction_code
    fill_in "Transaction result", with: @union_pay_bank.transaction_result
    fill_in "Upi accepted", with: @union_pay_bank.upi_accepted
    fill_in "Upi decal displayed after visit", with: @union_pay_bank.upi_decal_displayed_after_visit
    fill_in "Upi decal displayed before visit", with: @union_pay_bank.upi_decal_displayed_before_visit
    fill_in "User", with: @union_pay_bank.user_id
    fill_in "Why test not allowed", with: @union_pay_bank.why_test_not_allowed
    click_on "Update Union pay bank"

    assert_text "Union pay bank was successfully updated"
    click_on "Back"
  end

  test "destroying a Union pay bank" do
    visit union_pay_banks_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Union pay bank was successfully destroyed"
  end
end
