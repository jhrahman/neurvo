# Running Neurvo locally (macOS, Docker)

Tested target: MacBook Air (Apple Silicon), Docker Desktop with about 8 GB of memory (10 to 12 GB is more comfortable). On Windows,
use WSL 2 and run everything from the Linux file system; the steps in the [README](../../README.md#try-it-on-your-computer) apply.

## One-time setup

1. Install Docker Desktop (`brew install --cask docker`), start it, and set Resources > Memory to 8 GB.
2. From the repo root:

   ```bash
   docker network create gateway                                        # hocuspocus joins it; normally made by the optional TLS stack
   cp docker-compose.override.example.yml docker-compose.override.yml   # publishes ports 3000 and 4200
   bin/compose setup      # builds images, installs gems and npm packages, migrates and seeds the database
   bin/compose start      # db, cache, hocuspocus and the frontend dev server
   bin/compose up -d backend
   ```

   `config/database.yml` must not exist (it doesn't in this repo). The first `setup` takes 15 to 30 minutes.
   The `DEV_UID`/`DEV_GID` warnings from compose are harmless.
3. Open <http://localhost:3000> and log in as `admin` / `admin` (you are asked to change the password). The page title should
   read "Sign in | Neurvo". A fresh database only has the upstream demo data until you run the sample workspace below.

## Sample workspace (team, projects, sprints, bugs)

```bash
bin/compose exec backend bundle exec rake neurvo:seed
```

Builds a small, realistic dev/QA workspace and removes the upstream demo projects and users (keep them with
`KEEP_UPSTREAM_DEMO=1`). To set up only the Neurvo workflow, types, fields and roles without people or projects, run it with
`CONFIG_ONLY=1`; this is what a production instance uses (see [DEPLOY.md](DEPLOY.md)). Safe to re-run: configuration is upserted and the sample projects are rebuilt. Shared
configuration (statuses, types, fields, roles, team) is in `lib/neurvo/seed_data.yml`; each project has its own file in
`lib/neurvo/seed_data/` with its tickets, boards, sprints, comments, saved views, meetings and wiki.

| Project | Key | What it shows |
|---|---|---|
| Web Application - GoFleet | `GOFLEET` | Transportation platform: dispatch, live tracking, Driver app, billing |
| Web Application - QuickCart | `QCART` | E-commerce: checkout, search, inventory, returns |
| Platform & DevOps | `OPS` | Infrastructure work, incident postmortem, the engineering handbook |
| Neurvo | `NEU` | Our own tool, built with the same process |

- About two dozen tickets per product: epics with stories and sub-tasks, bugs at every stage of the bug lifecycle, a
  change request, a feature request, support requests, a design task, QA tasks and a release milestone.
- Boards per product: Sprint board, Bug triage, Release plan (columns are versions) and Support queue.
- Issue keys like `GOFLEET-15`; types Epic, Story, Task, Sub-task, Bug, Feature Request, Change Request, Support
  Request, Milestone. Workflow: To Do, In Progress, In Review, Ready for QA, In QA, Done (plus Reopened, Blocked,
  Waiting on Customer, Won't Do).
- Bug fields: Severity, Environment, Platform, Found in build, Fixed in build. Support Request fields: Customer,
  Support channel, Business impact. Per-type description templates.
- Sprints (previous completed, current active, next in planning) with goals, releases, saved views (My open work, Open
  bugs, Ready for QA, release scope, Support queue) listed under "Public" in the work package side menu.
- Meetings: daily stand-up, bug triage and sprint planning per product; release go/no-go in Platform & DevOps. Sprints
  run Monday to Friday; all times in Asia/Dhaka.
- Wiki: per product an overview, architecture, test strategy or requirements and a runbook; the engineering handbook
  (workflow and definition of done, bug lifecycle and severity, sprint rituals, release checklist, a blameless
  postmortem) in Platform & DevOps.
- Comments contain real @mentions, so inboxes fill up about 5 minutes after seeding (journal aggregation), as long as
  the `worker` container is running.
- Organization: "Ocean IT Solutions", a fictional company (Administration > System settings > Organization name), shown on the Home page. Change it to your own.
- QA hand-over: tickets in In QA are assigned to a QA engineer; the QA lead has regression and smoke-test tasks (one
  overdue).
- Roles and permissions: [ROLES.md](ROLES.md); every sample user with username, password and role: [USERS.md](USERS.md).
- Team (password `Neurvo-Dev-2026!`): imran.chowdhury, ayesha.karim (product managers), daniel.brooks (tech lead),
  rafi.hasan, sofia.martins, arif.rahman, kenji.watanabe, priya.nair (developers), maya.patel (UX designer),
  nusrat.jahan (QA lead), marco.rossi, lena.fischer (QA), tanvir.ahmed (DevOps).

## What to restart after a change

Most edits are picked up on the next page load. These are not:

| You changed | Restart | Why |
|---|---|---|
| A locale file (`config/locales/*.yml`, `js-en.yml`) | `bin/compose restart backend` | Translations load at boot |
| A new setting, route, initializer, or `config/schemas/*.json` | `bin/compose restart backend` | Loaded at boot; a schema that does not list a new preference silently drops it |
| A **new** Stimulus controller file | `bin/compose restart frontend` | The dev bundle lists controllers at build time (editing an existing one needs nothing) |
| The rich text editor build | See [editor/README.md](editor/README.md) | It is built outside this repo and copied in |
| Seed data (`lib/neurvo/seed_data*`) | Re-run `rake neurvo:seed` or `CONFIG_ONLY=1` | Data, not code |

## Where the Neurvo features live

| Feature | Start here |
|---|---|
| Role-based Home cards | `app/components/homescreen/card_catalog.rb` (cards, defaults, role mapping) and `app/views/my/home_cards.html.erb` |
| Comments tab and threads | `app/components/work_packages/activities_tab/` and `app/controllers/work_packages/activities_tab_controller.rb` |
| Neurvo-only styles | `frontend/src/global_styles/neurvo/` |
| Preset avatars | `lib/neurvo/avatars/` and `modules/avatars/` |
| Sample data and roles | `lib/neurvo/seed.rb` and `lib/neurvo/seed_data*` |
| Every upstream file we touched | [CHANGES.md](CHANGES.md) |

## Daily use

| Task | Command |
|---|---|
| Start everything in the background | `bin/compose start && bin/compose up -d backend worker` |
| Follow backend logs | `bin/compose logs -f backend` |
| Stop | `bin/compose stop` |
| Run specs | `bin/compose rspec spec/models/setting_spec.rb` |
| Rails console | `bin/compose exec backend bundle exec rails console` |
| Pick up edits to `js-en.yml` in the frontend | `bin/compose exec backend bundle exec rake assets:export_locales` |
| Wipe everything (needs `setup` again) | `bin/compose reset` |

Do not start the optional services in `docker/dev/` (Keycloak, Nextcloud, GitLab, MinIO and so on) unless a task needs them.
The frontend dev server (Angular) is slow on the first compile; wait until the backend log shows the page can be served.

## Sharing your local Neurvo (Cloudflare quick tunnel)

Pages load their scripts from `http://localhost:4200`, which only works on your Mac, so don't tunnel port 3000.
Tunnel the share proxy instead:

```bash
bin/neurvo-share                                   # terminal 1: serves app + assets on http://localhost:3100
cloudflared tunnel --url http://localhost:3100     # terminal 2: prints the public https://…trycloudflare.com URL
```

The proxy hides the dev-only pages (`/letter_opener` with every email incl. password resets, `/good_job`,
`/lookbook`, `/rails/*`). Rails keeps seeing `http://localhost:3000`, so its host name and HTTPS settings need no
change and the admin "Hostname/HTTPS mode setup mismatch" warnings do not appear; the proxy maps links,
redirects and form values between that and the public URL.

Before you share the link:

- Anyone with the URL reaches the login page. The sample team's password is in this file, so share only with
  people you trust, or change those passwords, and delete the `qa` admin account.
- This is development mode: error pages show stack traces and source snippets.
- Stop `cloudflared` (Ctrl+C) when you are done; quick-tunnel URLs change on every start.
- Run the frontend with `--no-hmr` (see the override below). With hot module replacement each page loads ~250
  extra component files, and Cloudflare answers the burst with 429, so logos, icons and avatars go missing.

## Memory (Docker Desktop with 8 GB)

The Angular dev server alone needs about 4 GB while compiling. With backend, worker, database and a test database
running, it can be OOM-killed (`neurvo-frontend-1` exits with 137). Stop what you don't need
(`bin/compose stop db-test` after running specs) or give Docker Desktop 10 to 12 GB if your Mac allows it.
The worker grows over a long session (2 GB+); `bin/compose restart worker` gives that memory back.

Upstream lets the dev server grow to an 8 GB heap. Cap it in your local `docker-compose.override.yml`:

```yaml
services:
  frontend:
    command: "node --max_old_space_size=3072 ./node_modules/@angular/cli/bin/ng serve --host 0.0.0.0 --no-hmr"
```

## Running specs

Browser (feature) specs need Selenium images that have no arm64 builds, so `bin/compose rspec` cannot start on Apple
Silicon. Model, helper, view, component and request specs run fine without them:

```bash
bin/compose up -d db-test
bin/compose run --rm --no-deps --entrypoint bash backend-test -lc 'bundle exec rspec spec/models/user_preference_spec.rb'
bin/compose stop db-test
```

The first run needs `RAILS_ENV=test bundle exec rails db:create db:schema:load` inside the same container.

