require "application_system_test_case"

class ChefWumujyisTest < ApplicationSystemTestCase
  setup do
    @chef_wumujyi = chef_wumujyis(:one)
  end

  test "visiting the index" do
    visit chef_wumujyis_url
    assert_selector "h1", text: "Chef Wumujyis"
  end

  test "creating a Chef wumujyi" do
    visit chef_wumujyis_url
    click_on "New Chef Wumujyi"

    fill_in "Customer name", with: @chef_wumujyi.customer_name
    fill_in "Fueled value", with: @chef_wumujyi.fueled_value
    fill_in "Plate number", with: @chef_wumujyi.plate_number
    fill_in "Service station name", with: @chef_wumujyi.service_station_name
    fill_in "Telephone number", with: @chef_wumujyi.telephone_number
    fill_in "Vehicle type", with: @chef_wumujyi.vehicle_type
    click_on "Create Chef wumujyi"

    assert_text "Chef wumujyi was successfully created"
    click_on "Back"
  end

  test "updating a Chef wumujyi" do
    visit chef_wumujyis_url
    click_on "Edit", match: :first

    fill_in "Customer name", with: @chef_wumujyi.customer_name
    fill_in "Fueled value", with: @chef_wumujyi.fueled_value
    fill_in "Plate number", with: @chef_wumujyi.plate_number
    fill_in "Service station name", with: @chef_wumujyi.service_station_name
    fill_in "Telephone number", with: @chef_wumujyi.telephone_number
    fill_in "Vehicle type", with: @chef_wumujyi.vehicle_type
    click_on "Update Chef wumujyi"

    assert_text "Chef wumujyi was successfully updated"
    click_on "Back"
  end

  test "destroying a Chef wumujyi" do
    visit chef_wumujyis_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Chef wumujyi was successfully destroyed"
  end
end
