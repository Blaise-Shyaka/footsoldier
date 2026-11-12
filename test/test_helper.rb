ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# Tests prove nothing about row-level security when they run as a role that bypasses it
# (ADR-0004), so the suite refuses to start as one.
begin
  ActiveRecord::Base.with_connection { |connection| Tenancy::DatabaseRoleCheck.verify!(connection) }
rescue Tenancy::DatabaseRoleCheck::PrivilegedRoleError => error
  abort "#{error.message}\n\nThe test suite must connect as footsoldier_app: run bin/setup, and " \
    "if DATABASE_URL is set, make it connect as footsoldier_app (it replaces the primary entry " \
    "in config/database.yml)."
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    # Runs the block on a connection of the owner role (config/database.yml), for the schema
    # changes the suite's role may not make, such as a table of a test's own. The connection is
    # outside the test's transaction, so what the block does is committed: undo it after the
    # test, in after_teardown once super has rolled the test back.
    def with_owner_connection
      owner_config = Footsoldier::DatabaseRoles.owner_config_for(ActiveRecord::Base.connection_db_config)
      connection = ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.new(owner_config.configuration_hash)
      yield connection
    ensure
      connection&.disconnect!
    end
  end
end
