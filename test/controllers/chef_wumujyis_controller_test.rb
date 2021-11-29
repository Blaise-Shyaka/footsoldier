require "test_helper"

class ChefWumujyisControllerTest < ActionDispatch::IntegrationTest
  setup do
    @chef_wumujyi = chef_wumujyis(:one)
  end

  test "should get index" do
    get chef_wumujyis_url
    assert_response :success
  end

  test "should get new" do
    get new_chef_wumujyi_url
    assert_response :success
  end

  test "should create chef_wumujyi" do
    assert_difference('ChefWumujyi.count') do
      post chef_wumujyis_url, params: { chef_wumujyi: { customer_name: @chef_wumujyi.customer_name, fueled_value: @chef_wumujyi.fueled_value, plate_number: @chef_wumujyi.plate_number, service_station_name: @chef_wumujyi.service_station_name, telephone_number: @chef_wumujyi.telephone_number, vehicle_type: @chef_wumujyi.vehicle_type } }
    end

    assert_redirected_to chef_wumujyi_url(ChefWumujyi.last)
  end

  test "should show chef_wumujyi" do
    get chef_wumujyi_url(@chef_wumujyi)
    assert_response :success
  end

  test "should get edit" do
    get edit_chef_wumujyi_url(@chef_wumujyi)
    assert_response :success
  end

  test "should update chef_wumujyi" do
    patch chef_wumujyi_url(@chef_wumujyi), params: { chef_wumujyi: { customer_name: @chef_wumujyi.customer_name, fueled_value: @chef_wumujyi.fueled_value, plate_number: @chef_wumujyi.plate_number, service_station_name: @chef_wumujyi.service_station_name, telephone_number: @chef_wumujyi.telephone_number, vehicle_type: @chef_wumujyi.vehicle_type } }
    assert_redirected_to chef_wumujyi_url(@chef_wumujyi)
  end

  test "should destroy chef_wumujyi" do
    assert_difference('ChefWumujyi.count', -1) do
      delete chef_wumujyi_url(@chef_wumujyi)
    end

    assert_redirected_to chef_wumujyis_url
  end
end
