require "test_helper"

class Tenancy::SchemaLintTest < ActiveSupport::TestCase
  # The policy from ADR-0004, as a migration writes it.
  TENANT_POLICY_SQL = "agency_id = NULLIF(current_setting('app.agency_id', true), '')::bigint".freeze

  test "the schema follows the tenant table rules" do
    assert_empty violations, "Tenant tables break the rules of ADR-0004:\n#{violations.join("\n")}"
  end

  test "tenant tables built by the rules pass" do
    create_tenant_tables

    assert_empty violations
  end

  test "a tenant table added by hand without a policy fails" do
    execute <<~SQL
      CREATE TABLE lint_notes (
        id bigserial PRIMARY KEY,
        agency_id bigint NOT NULL REFERENCES agencies (id)
      );
      CREATE INDEX ON lint_notes (agency_id);
    SQL

    assert_equal [
      "lint_notes: row-level security is not enabled",
      "lint_notes: row-level security is not forced, so the table's owner bypasses it",
      "lint_notes: no tenant policy: expected a permissive policy FOR ALL USING #{Tenancy::SchemaLint::TENANT_POLICY}"
    ], violations
  end

  test "row-level security must be forced" do
    create_tenant_tables
    execute "ALTER TABLE lint_tasks NO FORCE ROW LEVEL SECURITY"

    assert_violations "lint_tasks: row-level security is not forced"
  end

  test "the policy must treat a missing setting as no agency" do
    create_tenant_tables
    execute <<~SQL
      DROP POLICY tenant_isolation ON lint_tasks;
      CREATE POLICY tenant_isolation ON lint_tasks USING (agency_id = current_setting('app.agency_id')::bigint);
    SQL

    assert_violations "lint_tasks: no tenant policy", "lint_tasks: policy tenant_isolation is permissive and is not the tenant policy"
  end

  test "the policy must not let rows be written into other agencies" do
    create_tenant_tables
    execute <<~SQL
      DROP POLICY tenant_isolation ON lint_tasks;
      CREATE POLICY tenant_isolation ON lint_tasks USING (#{TENANT_POLICY_SQL}) WITH CHECK (true);
    SQL

    assert_violations "lint_tasks: no tenant policy", "lint_tasks: policy tenant_isolation is permissive and is not the tenant policy"
  end

  test "a second permissive policy fails, a restrictive one does not" do
    create_tenant_tables
    execute "CREATE POLICY lint_hide_drafts ON lint_tasks AS RESTRICTIVE USING (true)"
    assert_empty violations

    execute "CREATE POLICY lint_read_all ON lint_tasks FOR SELECT USING (true)"
    assert_violations "lint_tasks: policy lint_read_all is permissive and is not the tenant policy"
  end

  test "agency_id must not allow NULL" do
    create_tenant_tables
    execute "ALTER TABLE lint_tasks ALTER COLUMN agency_id DROP NOT NULL"

    assert_violations "lint_tasks: agency_id allows NULL"
  end

  test "an index must start with agency_id and cover every row" do
    create_tenant_tables
    execute "DROP INDEX lint_tasks_agency_id_project_id_idx"
    assert_violations "lint_tasks: no index starts with agency_id"

    execute "CREATE INDEX lint_tasks_project_id_agency_id_idx ON lint_tasks (project_id, agency_id)"
    assert_violations "lint_tasks: no index starts with agency_id"

    execute "CREATE INDEX lint_tasks_agency_id_partial_idx ON lint_tasks (agency_id) WHERE project_id > 0"
    assert_violations "lint_tasks: no index starts with agency_id"
  end

  test "a foreign key to a tenant parent must include agency_id" do
    create_tenant_tables
    execute <<~SQL
      ALTER TABLE lint_tasks DROP CONSTRAINT lint_tasks_project_fkey;
      ALTER TABLE lint_tasks ADD CONSTRAINT lint_tasks_project_fkey FOREIGN KEY (project_id) REFERENCES lint_projects (id);
      ALTER TABLE lint_tasks ADD FOREIGN KEY (agency_id) REFERENCES agencies (id);
    SQL

    assert_violations "lint_tasks: foreign key lint_tasks_project_fkey to lint_projects leaves out agency_id"
  end

  test "agency_id must be in a foreign key" do
    create_tenant_tables
    execute "ALTER TABLE lint_tasks DROP CONSTRAINT lint_tasks_project_fkey"

    assert_violations "lint_tasks: agency_id is in no foreign key to agencies or to a tenant parent"
  end

  test "a table that references a tenant table must have agency_id" do
    create_tenant_tables
    execute "CREATE TABLE lint_comments (id bigserial PRIMARY KEY, task_id bigint NOT NULL REFERENCES lint_tasks (id))"

    assert_violations "lint_comments: foreign key lint_comments_task_id_fkey references tenant table lint_tasks"
  end

  private
    def violations
      ActiveRecord::Base.with_connection { |connection| Tenancy::SchemaLint.violations(connection) }
    end

    # The tables are created inside the test's transaction, so PostgreSQL drops them again when
    # the test rolls back.
    def execute(sql)
      ActiveRecord::Base.with_connection { |connection| connection.execute(sql) }
    end

    # A tenant table under agencies and a child under it, each following every rule. The
    # projects policy also states WITH CHECK, which the tasks policy leaves to default to USING.
    def create_tenant_tables
      execute <<~SQL
        CREATE TABLE lint_projects (
          id bigserial PRIMARY KEY,
          agency_id bigint NOT NULL REFERENCES agencies (id),
          UNIQUE (agency_id, id)
        );
        CREATE TABLE lint_tasks (
          id bigserial PRIMARY KEY,
          agency_id bigint NOT NULL,
          project_id bigint NOT NULL,
          CONSTRAINT lint_tasks_project_fkey FOREIGN KEY (agency_id, project_id) REFERENCES lint_projects (agency_id, id)
        );
        CREATE INDEX lint_tasks_agency_id_project_id_idx ON lint_tasks (agency_id, project_id);
      SQL

      { "lint_projects" => "WITH CHECK (#{TENANT_POLICY_SQL})", "lint_tasks" => "" }.each do |table, with_check|
        execute <<~SQL
          ALTER TABLE #{table} ENABLE ROW LEVEL SECURITY;
          ALTER TABLE #{table} FORCE ROW LEVEL SECURITY;
          CREATE POLICY tenant_isolation ON #{table} USING (#{TENANT_POLICY_SQL}) #{with_check};
        SQL
      end
    end

    # Asserts the violations, in order, by how each one starts.
    def assert_violations(*starts)
      found = violations
      message = "Expected violations starting with:\n#{starts.join("\n")}\nGot:\n#{found.join("\n")}"

      assert_equal starts.size, found.size, message
      starts.zip(found).each { |start, violation| assert violation.start_with?(start), message }
    end
end
