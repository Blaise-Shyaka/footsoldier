# Footsoldier

Footsoldier is a multi-tenant platform for field data collection: agencies design forms, field
agents ("footsoldiers") capture submissions, and clients see the results. This is the Rails 8
rebuild. Read [`docs/architecture/README.md`](docs/architecture/README.md) before working on it,
and [`CLAUDE.md`](CLAUDE.md) for how changes are delivered. The legacy Rails 6.1 app is kept at
the `legacy-v1` tag.

## Requirements

- Ruby 4.0.9 (`.ruby-version`)
- PostgreSQL 17 or later, running locally and reachable as your OS user
- Node.js 26 (`.node-version`) and Yarn 1.22

## Set up and run

```bash
bin/setup
```

This installs gems and JavaScript packages, creates the development and test databases, and
starts the app. To set up without starting the app, run `bin/setup --skip-server`. To start it
later:

```bash
bin/dev
```

The app runs at <http://localhost:3000>; <http://localhost:3000/up> answers 200 when it is
healthy. `bin/dev` runs the Rails server and the esbuild and Tailwind watchers together.

**Homebrew's Ruby:** `bundle install` can fail with `Errno::EACCES` on `rdoc_plugin.rb`,
because Bundler tries to rewrite a read-only file inside Homebrew's Ruby. Install Ruby with a
version manager such as mise or rbenv instead, or set `BUNDLE_PATH` to a directory you own.

## Test

```bash
bin/rails test
```

`bin/ci` runs everything CI checks: RuboCop, bundler-audit, `yarn audit`, Brakeman, the tests
and the seeds.

## Production configuration

The Docker image (`Dockerfile`) runs Puma behind Thruster. Configuration comes from the
environment; nothing secret is committed.

| Variable | Purpose |
|----------|---------|
| `SECRET_KEY_BASE` | Signs and encrypts cookies and sessions; generate one with `bin/rails secret` |
| `FOOTSOLDIER_DATABASE_PASSWORD` | Password of the `footsoldier` database role |
| `SOLID_QUEUE_IN_PUMA` | Set to `true` to run the job workers inside the web process, so one container serves both |

Production uses four PostgreSQL databases on one server: `footsoldier_production` and its
`_cache`, `_queue` and `_cable` companions for Solid Cache, Solid Queue and Solid Cable
([doc 08](docs/architecture/08-deployment-and-operations.md)).
