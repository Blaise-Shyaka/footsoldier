require "test_helper"

class Tenancy::ScopedTest < ActiveSupport::TestCase
  # A tenant-owned model for these tests only. Its table is created inside each test's
  # transaction, so PostgreSQL drops it again when the test rolls back.
  class Note < ApplicationRecord
    self.table_name = "tenancy_scoped_test_notes"
    include Tenancy::Scoped
  end

  setup do
    Note.with_connection do |connection|
      connection.create_table :tenancy_scoped_test_notes do |t|
        t.references :agency, null: false, foreign_key: true
        t.string :body, null: false
      end
    end
    Note.reset_column_information

    @alpha = tenancy_agencies(:alpha)
    @bravo = tenancy_agencies(:bravo)
    Tenancy.across_agencies(:maintenance) do
      @alpha_note = Note.create!(agency: @alpha, body: "alpha's note")
      @bravo_note = Note.create!(agency: @bravo, body: "bravo's note")
    end
  end

  test "using a tenant model without a tenant raises" do
    assert_raises(Tenancy::NoTenantError) { Note.all.to_a }
    assert_raises(Tenancy::NoTenantError) { Note.count }
    assert_raises(Tenancy::NoTenantError) { Note.find(@alpha_note.id) }
    assert_raises(Tenancy::NoTenantError) { Note.new(body: "orphan") }
  end

  test "the error names the model and both ways out" do
    error = assert_raises(Tenancy::NoTenantError) { Note.count }

    assert_match "Tenancy::ScopedTest::Note", error.message
    assert_match "Current.agency", error.message
    assert_match "Tenancy.across_agencies", error.message
  end

  test "with a tenant, only that tenant's rows return" do
    Current.agency = @alpha

    assert_equal [ @alpha_note ], Note.all.to_a
    assert_equal 1, Note.count
    assert_empty Note.where(body: "bravo's note")
    assert_raises(ActiveRecord::RecordNotFound) { Note.find(@bravo_note.id) }
  end

  test "new records belong to the current agency" do
    Current.agency = @alpha

    assert_equal @alpha, Note.create!(body: "new").agency
  end

  test "a record cannot be saved into another agency" do
    Current.agency = @alpha

    assert_raises(Tenancy::TenantMismatchError) { Note.create!(agency: @bravo, body: "misplaced") }
    assert_equal 2, Tenancy.across_agencies(:maintenance) { Note.count }
  end

  test "a record cannot move to another agency" do
    Current.agency = @alpha
    note = Note.find(@alpha_note.id)

    assert_raises(ActiveRecord::ReadonlyAttributeError) { note.agency = @bravo }
    assert_raises(ActiveRecord::ReadonlyAttributeError) { note.agency_id = @bravo.id }
  end

  test "platform and maintenance code sees every agency's rows" do
    assert_equal 2, Tenancy.across_agencies(:platform) { Note.count }
    assert_equal 2, Tenancy.across_agencies(:maintenance) { Note.count }
  end

  test "across_agencies lifts the scope even when a tenant is set" do
    Current.agency = @alpha

    assert_equal 2, Tenancy.across_agencies(:platform) { Note.count }
    assert_equal 1, Note.count
  end

  test "across_agencies accepts only the platform and maintenance reasons" do
    assert_raises(ArgumentError) { Tenancy.across_agencies(:reporting) { Note.count } }
    assert_not Tenancy.across_agencies?
  end

  test "across_agencies ends with its block, even when the block raises" do
    assert_raises(RuntimeError) { Tenancy.across_agencies(:platform) { raise "boom" } }

    assert_not Tenancy.across_agencies?
    assert_raises(Tenancy::NoTenantError) { Note.count }
  end

  test "a nested across_agencies restores the outer reason" do
    Tenancy.across_agencies(:platform) do
      Tenancy.across_agencies(:maintenance) { assert_equal :maintenance, Tenancy.across_agencies_reason }

      assert_equal :platform, Tenancy.across_agencies_reason
    end
  end

  test "across_agencies does not reach other threads" do
    Tenancy.across_agencies(:platform) do
      result = Thread.new { Note.count rescue $! }.value

      assert_kind_of Tenancy::NoTenantError, result
    end
  end
end
