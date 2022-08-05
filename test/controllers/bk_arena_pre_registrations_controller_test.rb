require "test_helper"

class BkArenaPreRegistrationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @bk_arena_pre_registration = bk_arena_pre_registrations(:one)
  end

  test "should get index" do
    get bk_arena_pre_registrations_url
    assert_response :success
  end

  test "should get new" do
    get new_bk_arena_pre_registration_url
    assert_response :success
  end

  test "should create bk_arena_pre_registration" do
    assert_difference('BkArenaPreRegistration.count') do
      post bk_arena_pre_registrations_url, params: { bk_arena_pre_registration: {  } }
    end

    assert_redirected_to bk_arena_pre_registration_url(BkArenaPreRegistration.last)
  end

  test "should show bk_arena_pre_registration" do
    get bk_arena_pre_registration_url(@bk_arena_pre_registration)
    assert_response :success
  end

  test "should get edit" do
    get edit_bk_arena_pre_registration_url(@bk_arena_pre_registration)
    assert_response :success
  end

  test "should update bk_arena_pre_registration" do
    patch bk_arena_pre_registration_url(@bk_arena_pre_registration), params: { bk_arena_pre_registration: {  } }
    assert_redirected_to bk_arena_pre_registration_url(@bk_arena_pre_registration)
  end

  test "should destroy bk_arena_pre_registration" do
    assert_difference('BkArenaPreRegistration.count', -1) do
      delete bk_arena_pre_registration_url(@bk_arena_pre_registration)
    end

    assert_redirected_to bk_arena_pre_registrations_url
  end
end
