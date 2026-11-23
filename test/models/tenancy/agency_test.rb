require "test_helper"

class Tenancy::AgencyTest < ActiveSupport::TestCase
  test "the fixtures are valid and active" do
    assert tenancy_agencies(:alpha).valid?
    assert tenancy_agencies(:alpha).active?
  end

  test "a new agency is active" do
    assert_predicate Tenancy::Agency.new, :active?
  end

  test "status is active or suspended" do
    agency = tenancy_agencies(:alpha)

    agency.status = "suspended"
    assert agency.valid?

    agency.status = "archived"
    assert_not agency.valid?
    assert_includes agency.errors[:status], "is not included in the list"
  end

  test "name and data region are required" do
    agency = Tenancy::Agency.new(slug: "charlie")

    assert_not agency.valid?
    assert_includes agency.errors[:name], "can't be blank"
    assert_includes agency.errors[:data_region], "can't be blank"
  end

  test "the slug is stripped and lowercased" do
    assert_equal "charlie-research", Tenancy::Agency.new(slug: "  Charlie-Research ").slug
  end

  test "the slug is a valid DNS label" do
    agency = tenancy_agencies(:alpha)

    [ "charlie", "charlie-2", "c" * 63 ].each do |slug|
      agency.slug = slug
      assert agency.valid?, "#{slug.inspect} should be valid"
    end

    [ "-charlie", "charlie-", "char--lie", "char_lie", "char lie", "c" * 64 ].each do |slug|
      agency.slug = slug
      assert_not agency.valid?, "#{slug.inspect} should be invalid"
    end
  end

  test "slugs are unique regardless of case" do
    agency = Tenancy::Agency.new(slug: "ALPHA", name: "Another Alpha", data_region: "rw")

    assert_not agency.valid?
    assert_includes agency.errors[:slug], "has already been taken"
  end

  test "the data region is a lowercase code" do
    agency = tenancy_agencies(:alpha).dup
    agency.slug = "charlie"

    agency.data_region = "RW"
    assert_not agency.valid?

    agency.data_region = "eu-west"
    assert agency.valid?
  end

  test "the data region cannot change once the agency exists" do
    assert_raises(ActiveRecord::ReadonlyAttributeError) do
      tenancy_agencies(:alpha).data_region = "ke"
    end
  end
end
