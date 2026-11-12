# The app runs as footsoldier_app and migrates as footsoldier_owner (ADR-0004). config/database.yml
# pairs an app entry with an owner entry for each database; this file connects the two halves.
#
# The owner creates every table, so the app role can use none of them until the owner grants it
# access. Every schema load and migration ends with those grants: on the tables and sequences that
# exist, and by default on the ones the owner creates later. That covers db:prepare, db:migrate,
# db:test:prepare and the per-worker databases of parallel tests.
#
# The module is defined here, not under app/ or lib/, because it is prepended to a framework
# module during boot and must not be reloaded.
module Footsoldier
  module DatabaseRoles
    # Not TRUNCATE: it ignores row-level security. Not REFERENCES or TRIGGER: those are schema
    # changes, which belong to the owner.
    TABLE_PRIVILEGES = "SELECT, INSERT, UPDATE, DELETE".freeze
    # UPDATE lets fixtures reset primary key sequences with setval.
    SEQUENCE_PRIVILEGES = "USAGE, SELECT, UPDATE".freeze

    extend self

    # The owner entry for the database an app entry connects to.
    def owner_config_for(app_config)
      configs_in(app_config.env_name).find do |config|
        config.database_tasks? && config.database == app_config.database
      end
    end

    # The roles of the app entries that connect to an owner entry's database.
    def app_roles_for(owner_config)
      configs_in(owner_config.env_name)
        .select { |config| !config.database_tasks? && config.database == owner_config.database }
        .filter_map { |config| config.configuration_hash[:username] }
        .uniq
    end

    # Runs on a connection of the owner entry.
    def grant_to_app_roles(connection, owner_config)
      return unless owner_config.database_tasks?

      app_roles_for(owner_config).each do |role|
        role = connection.quote_column_name(role)
        connection.execute(<<~SQL)
          GRANT #{TABLE_PRIVILEGES} ON ALL TABLES IN SCHEMA public TO #{role};
          GRANT #{SEQUENCE_PRIVILEGES} ON ALL SEQUENCES IN SCHEMA public TO #{role};
          ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT #{TABLE_PRIVILEGES} ON TABLES TO #{role};
          ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT #{SEQUENCE_PRIVILEGES} ON SEQUENCES TO #{role};
        SQL
      end
    end

    # Prepended to ActiveRecord::Tasks::DatabaseTasks. During both methods, the tasks' connection
    # belongs to the owner entry being loaded or migrated.
    module GrantAfterSchemaChanges
      def load_schema(db_config, ...)
        super.tap { DatabaseRoles.grant_to_app_roles(migration_connection, db_config) }
      end

      def migrate(...)
        super.tap { DatabaseRoles.grant_to_app_roles(migration_connection, migration_connection_pool.db_config) }
      end
    end

    private
      def configs_in(env_name)
        ActiveRecord::Base.configurations.configs_for(env_name: env_name, include_hidden: true)
      end
  end
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Tasks::DatabaseTasks.singleton_class.prepend(Footsoldier::DatabaseRoles::GrantAfterSchemaChanges)
end
