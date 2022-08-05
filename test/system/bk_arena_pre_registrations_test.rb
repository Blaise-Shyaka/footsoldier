require "application_system_test_case"

class BkArenaPreRegistrationsTest < ApplicationSystemTestCase
  setup do
    @bk_arena_pre_registration = bk_arena_pre_registrations(:one)
  end

  test "visiting the index" do
    visit bk_arena_pre_registrations_url
    assert_selector "h1", text: "Bk Arena Pre Registrations"
  end

  test "creating a Bk arena pre registration" do
    visit bk_arena_pre_registrations_url
    click_on "New Bk Arena Pre Registration"

    click_on "Create Bk arena pre registration"

    assert_text "Bk arena pre registration was successfully created"
    click_on "Back"
  end

  test "updating a Bk arena pre registration" do
    visit bk_arena_pre_registrations_url
    click_on "Edit", match: :first

    click_on "Update Bk arena pre registration"

    assert_text "Bk arena pre registration was successfully updated"
    click_on "Back"
  end

  test "destroying a Bk arena pre registration" do
    visit bk_arena_pre_registrations_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Bk arena pre registration was successfully destroyed"
  end
end
