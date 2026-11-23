-- Creates the two PostgreSQL roles Footsoldier uses in every environment (ADR-0004; "Database
-- roles" in README.md). bin/setup and CI run it; run it as a superuser, because only a superuser
-- can create a role with BYPASSRLS. Running it again changes nothing: it creates missing roles
-- only and never sets or changes passwords.
--
-- footsoldier_owner owns the databases and their tables. Rails migrates and loads the schema as
-- this role. BYPASSRLS lets data migrations and maintenance see every agency's rows once tables
-- force row-level security; CREATEDB lets Rails create the databases, including one per worker
-- for parallel tests.
--
-- footsoldier_app is the role the app runs as. It is not a superuser, owns nothing and has no
-- BYPASSRLS, so row-level security applies to it. Rails grants it read and write access to the
-- owner's tables (config/initializers/database_roles.rb).
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'footsoldier_owner') THEN
    CREATE ROLE footsoldier_owner LOGIN NOSUPERUSER CREATEDB NOCREATEROLE BYPASSRLS;
  END IF;

  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'footsoldier_app') THEN
    CREATE ROLE footsoldier_app LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
END
$$;
