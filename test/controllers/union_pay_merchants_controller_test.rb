require "test_helper"

class UnionPayMerchantsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @union_pay_merchant = union_pay_merchants(:one)
  end

  test "should get index" do
    get union_pay_merchants_url
    assert_response :success
  end

  test "should get new" do
    get new_union_pay_merchant_url
    assert_response :success
  end

  test "should create union_pay_merchant" do
    assert_difference('UnionPayMerchant.count') do
      post union_pay_merchants_url, params: { union_pay_merchant: {  } }
    end

    assert_redirected_to union_pay_merchant_url(UnionPayMerchant.last)
  end

  test "should show union_pay_merchant" do
    get union_pay_merchant_url(@union_pay_merchant)
    assert_response :success
  end

  test "should get edit" do
    get edit_union_pay_merchant_url(@union_pay_merchant)
    assert_response :success
  end

  test "should update union_pay_merchant" do
    patch union_pay_merchant_url(@union_pay_merchant), params: { union_pay_merchant: {  } }
    assert_redirected_to union_pay_merchant_url(@union_pay_merchant)
  end

  test "should destroy union_pay_merchant" do
    assert_difference('UnionPayMerchant.count', -1) do
      delete union_pay_merchant_url(@union_pay_merchant)
    end

    assert_redirected_to union_pay_merchants_url
  end
end
