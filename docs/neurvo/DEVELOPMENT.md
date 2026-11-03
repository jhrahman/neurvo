# Running Neurvo locally (macOS, Docker)

Tested target: MacBook Air (Apple Silicon), Docker Desktop with about 8 GB of memory.

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
3. Open <http://localhost:3000> and log in as `admin` / `admin`. The demo seed creates 7 projects and 41 work packages.
   The login page title should read "Sign in | Neurvo".

## Sample workspace (team, projects, sprints, bugs)

```bash
bin/compose exec backend bundle exec rake neurvo:seed
```

Builds a realistic dev/QA workspace from `lib/neurvo/seed_data.yml` and removes the upstream demo projects and users
(keep them with `KEEP_UPSTREAM_DEMO=1`). Safe to re-run: configuration is upserted and the sample projects are rebuilt.

- Projects: ShopEase (SHOP) with ShopEase Web (WEB) and ShopEase Mobile (MOB), Platform & DevOps (OPS), Neurvo (NEU).
- Issue keys like `WEB-18`; types Epic, Story, Task, Sub-task, Bug, Feature Request, Change Request, Milestone.
- Workflow: To Do → In Progress → In Review → Ready for QA → In QA → Done (plus Reopened, Blocked, Won't Do).
- Bug fields: Severity, Environment, Platform, Found in build, Fixed in build. Per-type description templates.
- Sprints (previous completed, current active, next in planning), releases, boards (SQA Defects in SHOP, Web Kanban),
  saved views (Open bugs, Ready for QA, Production incidents, Feature & change requests).
- Team (password `Neurvo-Dev-2026!`): ayesha.karim (PM), daniel.brooks (tech lead), rafi.hasan, sofia.martins,
  kenji.watanabe, priya.nair (developers), nusrat.jahan (QA lead), marco.rossi, lena.fischer (QA), tanvir.ahmed (DevOps).

## Daily use

| Task | Command |
|---|---|
| Start everything in the background | `bin/compose start && bin/compose up -d backend worker` |
| Follow backend logs | `bin/compose logs -f backend` |
| Stop | `bin/compose stop` |
| Run specs | `bin/compose rspec spec/models/setting_spec.rb` |
| Rails console | `bin/compose exec backend bundle exec rails console` |
| Wipe everything (needs `setup` again) | `bin/compose reset` |

Do not start the optional services in `docker/dev/` (Keycloak, Nextcloud, GitLab, MinIO and so on) unless a task needs them.
The frontend dev server (Angular) is slow on the first compile; wait until the backend log shows the page can be served.
