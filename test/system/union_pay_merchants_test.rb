require "application_system_test_case"

class UnionPayMerchantsTest < ApplicationSystemTestCase
  setup do
    @union_pay_merchant = union_pay_merchants(:one)
  end

  test "visiting the index" do
    visit union_pay_merchants_url
    assert_selector "h1", text: "Union Pay Merchants"
  end

  test "creating a Union pay merchant" do
    visit union_pay_merchants_url
    click_on "New Union Pay Merchant"

    click_on "Create Union pay merchant"

    assert_text "Union pay merchant was successfully created"
    click_on "Back"
  end

  test "updating a Union pay merchant" do
    visit union_pay_merchants_url
    click_on "Edit", match: :first

    click_on "Update Union pay merchant"

    assert_text "Union pay merchant was successfully updated"
    click_on "Back"
  end

  test "destroying a Union pay merchant" do
    visit union_pay_merchants_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Union pay merchant was successfully destroyed"
  end
end
