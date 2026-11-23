# Footsoldier

Footsoldier is a multi-tenant platform for field data collection: agencies design forms, field
agents ("footsoldiers") capture submissions, and clients see the results. This is the Rails 8
rebuild. Read [`docs/architecture/README.md`](docs/architecture/README.md) before working on it,
and [`CLAUDE.md`](CLAUDE.md) for how changes are delivered. The legacy Rails 6.1 app is kept at
the `legacy-v1` tag.

## Requirements

- Ruby 4.0.9 (`.ruby-version`)
- PostgreSQL 17 or later, running locally, with your OS user as a superuser: `bin/setup` uses
  it to create the app's database roles (see [Database roles](#database-roles))
- Node.js 26 (`.node-version`) and Yarn 1.22

## Set up and run

```bash
bin/setup
```

This installs gems and JavaScript packages, creates the two database roles and the development
and test databases, and starts the app. To set up without starting the app, run
`bin/setup --skip-server`. To start it later:

```bash
bin/dev
```

The app runs at <http://localhost:3000>; <http://localhost:3000/up> answers 200 when it is
healthy. `bin/dev` runs the Rails server and the esbuild and Tailwind watchers together.

**Homebrew's Ruby:** `bundle install` can fail with `Errno::EACCES` on `rdoc_plugin.rb`,
because Bundler tries to rewrite a read-only file inside Homebrew's Ruby. Install Ruby with a
version manager such as mise or rbenv instead, or set `BUNDLE_PATH` to a directory you own.

## Database roles

The app connects to PostgreSQL as `footsoldier_app` and migrates as `footsoldier_owner`, in
every environment, because row-level security does not apply to a superuser, to a role with
`BYPASSRLS`, or to the owner of a table ([ADR-0004](docs/adr/0004-multi-tenancy.md)).

| Role | Used by | What it may do |
|------|---------|----------------|
| `footsoldier_app` | The app, its console and jobs, `db:seed`, the test suite | Read and write the tables. Not a superuser, owns nothing, no `BYPASSRLS` |
| `footsoldier_owner` | Migrations, schema loads and the other `db:` tasks | Owns the databases and tables; has `CREATEDB` and `BYPASSRLS`; not a superuser |

`config/database.yml` lists each database twice: `primary` connects as the app role and
`primary_owner` as the owner. Every migration and schema load ends with the owner granting the
app role `SELECT`, `INSERT`, `UPDATE` and `DELETE` on its tables, and the same by default on
tables it creates later (`config/initializers/database_roles.rb`). To open `psql` as the owner,
run `bin/rails dbconsole --database=primary_owner`.

`bin/setup` creates both roles by running `db/roles.sql` with `psql` as your OS user. Homebrew's
and Postgres.app's PostgreSQL make that user a superuser; if yours does not, run the file as one,
then `bin/setup` again:

```bash
sudo -u postgres psql --dbname=postgres < db/roles.sql
```

The roles have no passwords. If your PostgreSQL asks for them, give the roles passwords and put
those in `~/.pgpass`, not in `config/database.yml`.

**Databases created before the roles existed** belong to your OS user, so `footsoldier_owner`
can neither migrate nor recreate them. `bin/setup` stops and lists them; drop them with `dropdb`
and run it again.

The test suite stops before running anything when it connects as a role that can bypass
row-level security, and says why, for example:

```
The database role footsoldier_owner can bypass row-level security, so it would not apply to this
connection: it has BYPASSRLS and it owns, or is a member of the owner of, 2 tables (...).
```

`DATABASE_URL` replaces the settings of the app's entry, and `PRIMARY_OWNER_DATABASE_URL` those
of the owner's. Two checkouts of the repository on one machine, such as git worktrees, share
`footsoldier_test` and break each other's test runs; give each its own test database by pointing
both variables at it:

```bash
export RAILS_ENV=test
export DATABASE_URL=postgres://footsoldier_app@localhost/footsoldier_test_mine
export PRIMARY_OWNER_DATABASE_URL=postgres://footsoldier_owner@localhost/footsoldier_test_mine
bin/rails db:test:prepare test
```

## Test

```bash
bin/rails test
```

GitHub Actions ([`.github/workflows/ci.yml`](.github/workflows/ci.yml)) runs RuboCop,
Brakeman, bundler-audit and all the tests, system tests included, on every pull request and
every push to `main`. `bin/ci` runs the same checks locally, plus `yarn audit` and the seeds.

## Production configuration

The Docker image (`Dockerfile`) runs Puma behind Thruster. Configuration comes from the
environment; nothing secret is committed.

| Variable | Purpose |
|----------|---------|
| `SECRET_KEY_BASE` | Signs and encrypts cookies and sessions; generate one with `bin/rails secret` |
| `FOOTSOLDIER_APP_DATABASE_PASSWORD` | Password of the `footsoldier_app` database role, which the app connects as |
| `FOOTSOLDIER_OWNER_DATABASE_PASSWORD` | Password of the `footsoldier_owner` database role, which `bin/rails db:prepare` uses when the container starts |
| `SOLID_QUEUE_IN_PUMA` | Set to `true` to run the job workers inside the web process, so one container serves both |

Production uses four PostgreSQL databases on one server: `footsoldier_production` and its
`_cache`, `_queue` and `_cable` companions for Solid Cache, Solid Queue and Solid Cable
([doc 08](docs/architecture/08-deployment-and-operations.md)). Before the first deploy, a
superuser on that server runs `db/roles.sql` and gives both roles passwords. `db:prepare` then
creates the databases as `footsoldier_owner`; databases that already exist must belong to it.
