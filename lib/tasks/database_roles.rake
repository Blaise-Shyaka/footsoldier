# The db: tasks run as footsoldier_owner (config/database.yml). Most connect through the owner
# entries on their own, but these use ActiveRecord::Base's connection, which is the app role's, so
# they would fail on the first schema change.
namespace :db do
  task connect_as_owner: :load_config do
    app_config = ActiveRecord::Base.connection_db_config
    owner_config = Footsoldier::DatabaseRoles.owner_config_for(app_config) or
      raise "config/database.yml has no owner entry for #{app_config.database} in #{app_config.env_name}"

    ActiveRecord::Base.establish_connection(owner_config)
  end
end

%w[db:environment:set db:migrate:up db:migrate:down db:migrate:redo db:rollback db:forward].each do |task|
  Rake::Task[task].enhance([ "db:connect_as_owner" ])
end
