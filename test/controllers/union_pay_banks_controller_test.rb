require "test_helper"

class UnionPayBanksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @union_pay_bank = union_pay_banks(:one)
  end

  test "should get index" do
    get union_pay_banks_url
    assert_response :success
  end

  test "should get new" do
    get new_union_pay_bank_url
    assert_response :success
  end

  test "should create union_pay_bank" do
    assert_difference('UnionPayBank.count') do
      post union_pay_banks_url, params: { union_pay_bank: { atm_location: @union_pay_bank.atm_location, bank_name: @union_pay_bank.bank_name, is_visa_or_mastercard_displayed: @union_pay_bank.is_visa_or_mastercard_displayed, special_comments: @union_pay_bank.special_comments, transaction_code: @union_pay_bank.transaction_code, transaction_result: @union_pay_bank.transaction_result, upi_accepted: @union_pay_bank.upi_accepted, upi_decal_displayed_after_visit: @union_pay_bank.upi_decal_displayed_after_visit, upi_decal_displayed_before_visit: @union_pay_bank.upi_decal_displayed_before_visit, user_id: @union_pay_bank.user_id, why_test_not_allowed: @union_pay_bank.why_test_not_allowed } }
    end

    assert_redirected_to union_pay_bank_url(UnionPayBank.last)
  end

  test "should show union_pay_bank" do
    get union_pay_bank_url(@union_pay_bank)
    assert_response :success
  end

  test "should get edit" do
    get edit_union_pay_bank_url(@union_pay_bank)
    assert_response :success
  end

  test "should update union_pay_bank" do
    patch union_pay_bank_url(@union_pay_bank), params: { union_pay_bank: { atm_location: @union_pay_bank.atm_location, bank_name: @union_pay_bank.bank_name, is_visa_or_mastercard_displayed: @union_pay_bank.is_visa_or_mastercard_displayed, special_comments: @union_pay_bank.special_comments, transaction_code: @union_pay_bank.transaction_code, transaction_result: @union_pay_bank.transaction_result, upi_accepted: @union_pay_bank.upi_accepted, upi_decal_displayed_after_visit: @union_pay_bank.upi_decal_displayed_after_visit, upi_decal_displayed_before_visit: @union_pay_bank.upi_decal_displayed_before_visit, user_id: @union_pay_bank.user_id, why_test_not_allowed: @union_pay_bank.why_test_not_allowed } }
    assert_redirected_to union_pay_bank_url(@union_pay_bank)
  end

  test "should destroy union_pay_bank" do
    assert_difference('UnionPayBank.count', -1) do
      delete union_pay_bank_url(@union_pay_bank)
    end

    assert_redirected_to union_pay_banks_url
  end
end
