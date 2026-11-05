# Neurvo — project context for AI coding agents

> This file is the Neurvo layer on top of the upstream OpenProject instructions in `CLAUDE.md` / `AGENTS.md`.
> Follow both. Where they conflict, **this file wins**.

## What Neurvo is

Neurvo is a self-hosted project management and ticketing platform: **"the taste of Jira, for free."** It is a personal project. "Ocean IT Solutions" and every person in the sample data are fictional.
It is a customized fork of **OpenProject v17.9.6** (GPLv3), developed with AI-assisted development (Claude Code).

- **Intended users**: software teams of up to about 100 people: software engineers, SQA engineers, DevOps engineers, designers and project managers.
- **Goal**: a clean, fast, modern tool covering what most teams use every day: issues, boards, sprints, a roadmap and docs. It is deliberately **not** a feature-for-feature OpenProject clone.
- **Vision**: Neurvo is the hub of the team's toolset. Docmost gives the Confluence experience, and CI/CD, chat, monitoring and AI tools connect through a pluggable integration framework.
- **Maintainer**: an SQA engineer. Quality, tests and clear change logs matter.

## Environments

- **Development**: MacBook Air M5 (Apple Silicon, 16 GB RAM, 512 GB). Docker Desktop with about 8 GB of memory. Use the upstream Docker dev setup (`bin/compose`, see `docker/dev/CLAUDE.md`).
- **Production (later)**: Linux x86_64 server in a data center, run with Docker Compose.
- So everything must be container-based and configured through environment variables. Never hard-code Mac-specific paths, `localhost` URLs, secrets or credentials.
- Be mindful of the 16 GB of RAM: don't start optional services (Keycloak, Nextcloud, GitLab, MinIO and so on in `docker/dev/`) unless the task needs them.

## Golden rules

1. **Stay upgradable.** Upstream OpenProject releases updates and security fixes often, and Neurvo must be able to merge them.
   - Prefer, in this order: (a) admin settings and seed data → (b) configuration and environment variables → (c) code in our own module `modules/neurvo/` (patches, overrides, new features) → (d) direct edits to core files, only as a last resort, kept small.
   - Every core (non-`modules/neurvo`) file you change must be listed in `docs/neurvo/CHANGES.md` with a one-line reason. Create the file if it doesn't exist yet.
2. **Rename only what users see.** Never rename internal identifiers: Ruby namespaces (`OpenProject::`), gem names, `OPENPROJECT_*` env vars, API paths, database tables, CSS class prefixes (`op-`), or file names other than the logo assets. User-facing text, such as page titles, UI strings, emails and the English locale files (`config/locales/en.yml`, `config/locales/js-en.yml`, `modules/*/config/locales/en.yml`), should say **Neurvo**. No blind global search-and-replace: change strings deliberately and check the result in the UI.
3. **Respect the license.** Keep all copyright and license headers and the `COPYRIGHT`/`LICENSE` files (GPLv3). New files follow the upstream header rules. Where credit is due, the About and help pages should say "Neurvo is based on OpenProject".
4. **Do not remove or bypass Enterprise edition token checks.** If a feature we want is Enterprise-only, say so and propose building our own equivalent in `modules/neurvo/`.
5. **Hide before you delete.** To remove features users don't need, first disable them by default (project modules, menu entries, settings). Remove code or bundle modules only with my explicit approval, after checking dependencies.
6. **Plan first, then small steps.** For each phase or bigger task: explore, propose a plan, and wait for my approval. Then work in small commits on the `neurvo` branch.
7. **Test every change.** Add or update RSpec and frontend tests for what you change. Run only the relevant specs (`bin/compose rspec <path>`); the full suite is huge. Run the linters for touched files before committing. Tell me how to verify a change manually in the browser.
8. **Build for integrations and scale.** Neurvo is the hub of a growing toolset: Docmost first, more later. Every feature is API-first, every integration is a pluggable module, and nothing assumes a single server. See "Integrations and scalability" below; it applies to every phase, not only the integration work.

## Brand

Brand assets live in `neurvo-brand/` at the repo root. Read `neurvo-brand/README.md` first.

- `neurvo-brand/openproject-dropin/` mirrors upstream paths. Each file replaces an OpenProject logo or favicon with the same name and pixel size.
- `neurvo-brand/svg/` holds the master SVGs; `neurvo-brand/png/` holds large PNGs.
- Colors: **Neurvo Blue `#1276B9`** (primary), **Neurvo Green `#8DC543`** (accent, used sparingly), white.
- The wordmark font, Saira Semi Condensed, is only for the logo. The UI keeps Primer's system font stack.
- The mark is three connected nodes forming a check mark: "done / verified".

## Product scope

### Keep and polish (core Neurvo experience)
Work packages (issues), projects, boards (Kanban and Scrum), backlogs and sprints, Gantt as "Roadmap/Timeline", calendar, My page and project overview (dashboards), notifications and @mentions, search, saved filters/views, wiki and documents (with real-time collaboration via Hocuspocus), meetings, GitHub/GitLab integration, webhooks and the API, avatars, 2FA, OpenID Connect/SAML (for company single sign-on later), Excel/CSV/PDF export.

### Hide by default (keep the code; admins can re-enable)
Costs, budgets, cost reporting, resource management, team planner, external file storages (Nextcloud/OneDrive/SharePoint), LDAP groups and departments, BIM. Check which of these are Enterprise-only and report.

### Jira-like improvements to build (roadmap, phase 4)
- Default issue types **Epic, Story, Task, Bug, Sub-task**, with a simple default workflow: To Do → In Progress → In Review → QA → Done.
- **Readable issue keys** like `NEU-123` per project. Check first whether upstream already has something like this.
- **Bug template** fields: severity, environment, build/version, steps to reproduce, expected vs actual result, attachments.
- Fast creation: a quick-create dialog and keyboard shortcuts, plus a **command palette (⌘K / Ctrl+K)** for search and navigation.
- Better boards: swimlanes, WIP limits, quick filters.
- Sprint insights: burndown/velocity, sprint goal, and a sprint report.
- Releases (versions) with auto-generated release notes.
- Simplified navigation and menus for the core experience above.
- Check upstream's Jira importer for moving existing data in.

## Theme: improved Light and Dark

Upstream already supports theme modes per user (light, dark, high contrast, sync with OS; see `app/components/custom_styles/theme_selector_component.rb`) and admin color themes (`lib/open_project/custom_styles/color_themes.rb`). It uses GitHub's Primer design system.

Neurvo should:
- Ship **"Neurvo Light"** and **"Neurvo Dark"** as the default themes, built on Primer tokens with the brand colors (not hard-coded hex values everywhere). Default the user setting to "sync with OS".
- Make dark mode complete: no white flashes or unreadable spots in legacy Angular views, Gantt, boards, the backlogs page, the editors (CKEditor/BlockNote), date pickers, modals, PDF previews or empty-state images.
- Meet WCAG 2.1 AA contrast (4.5:1 for text) in both modes. Brand blue on dark backgrounds needs a lighter tint.
- Look modern: consistent spacing, radius and elevation; a clean header with the Neurvo logo; good empty states.
- Before changing anything, audit the current theming and send me screenshots or a list of the problem areas.

## Integrations and scalability

Neurvo is the **hub**: issues, sprints and releases live here, and other tools connect to it. Docmost will give the Confluence experience; more tools will follow. Adding the next integration must be a new module plus configuration, never a rewrite.

### Architecture principles

1. **Build on upstream extension points before inventing new ones.** Before designing anything, audit and report what OpenProject already provides:
   - the plugin/module system (`modules/`) and hooks,
   - API v3 (HAL+JSON, documented in `docs/api/`),
   - the webhooks module,
   - its OAuth 2 provider (OAuth applications) and OpenID Connect/SAML login,
   - the integration patterns used by the existing GitHub, GitLab and file-storage modules,
   - any existing wiki or test-management integrations (`docker/dev/` has XWiki and SquashTM setups).
2. **A shared integration framework in `modules/neurvo/`.** Build it once; every integration reuses it:
   - **Provider registry**: each integration registers itself with a name, settings schema, permissions and health check.
   - **Generic external links**: one model linking a work package, project or version to an external item (provider, external id, URL, title, cached preview, last synced). This is what powers "linked Docmost pages", "linked builds", "linked alerts" and so on.
   - **Admin UI**: one "Integrations" page under Administration to enable, configure and test each provider.
   - **Link previews**: pasting a supported URL renders a rich preview card.
   - **Inbound webhooks**: one receiver endpoint per provider, with signature verification, idempotency and replay protection.
   - **Outbound events**: internal domain events (issue created or updated, status changed, sprint started or completed, release published) published once and consumed by webhooks and integration subscribers.
3. **One module per integration**: `modules/neurvo_<provider>/`, for example `modules/neurvo_docmost/`. It must be self-contained, off by default, enabled and configured through the admin UI or environment variables, and removable without touching other code.
4. **Fail soft.** If an external tool is slow or down, Neurvo keeps working. Use short timeouts, background jobs (GoodJob) for sync and retries, cached previews, and a clear "integration unavailable" state in the UI, never an error page.
5. **API-first.** Every new Neurvo feature (issue keys, bug fields, sprint data, releases) is exposed in API v3 and documented in the OpenAPI spec, so integrations, automations and AI agents can use it. Version the API and never break existing endpoints.
6. **One identity for every tool.** Plan for a central identity provider. Keycloak is already in `docker/dev/keycloak/`; production may use the company's own provider. Neurvo, Docmost and later tools all log in through OpenID Connect, which gives one login and consistent users and groups. Service-to-service calls use OAuth 2 client credentials or scoped API tokens, never personal passwords.
7. **Security by default.** Secrets only in environment variables or encrypted settings. Least-privilege tokens per integration. Respect Neurvo permissions in everything an integration shows. Log integration actions for auditing.

### Docmost (first integration, the Confluence experience)

- Runs as its own container next to Neurvo, on its own subdomain (for example `docs.<company>`), with the same login through the identity provider.
- Inside Neurvo: a **"Docs" tab on issues and projects** listing linked Docmost pages, link previews for Docmost URLs, and **"Create page from issue"** (for test plans, specs, postmortems) using templates.
- Inside Docmost: links and previews pointing back to Neurvo issues (`NEU-123`).
- Later: unified search across Neurvo and Docmost.
- Before building, check Docmost's current API, webhook and single-sign-on support and its license terms (which features are in the free/community edition). Report the gaps.

### Future integration candidates (design for these, build later)

- **CI/CD** (GitHub Actions, GitLab CI, Jenkins): build and deploy status on issues and releases.
- **Chat** (Slack, Microsoft Teams, Google Chat, Mattermost): notifications, plus creating issues from messages.
- **Email-to-issue**: support or bug inbox.
- **Monitoring** (Sentry, Grafana/Prometheus alerts): automatically create bugs or incidents with a link back.
- **Test management**: test runs and results linked to issues and releases.
- **AI**: a Neurvo MCP server exposing the API so AI assistants can read and update issues safely.
- **Calendars**: iCal already exists upstream.

### Runtime scalability (from day one, even on the Mac)

- **Stateless web containers** with separate background-worker containers, so either can be scaled out independently.
- **External services**: PostgreSQL, the cache (memcached/Redis) and attachments in S3-compatible object storage (MinIO in `docker/dev/minio/`). The web container's local disk holds nothing important.
- **All configuration through environment variables**, with a documented `.env.example` for each service.
- **One reverse proxy** (Traefik or Caddy) routing subdomains (`neurvo.`, `docs.`, `sso.`) with HTTPS. Adding a tool means adding one container and one route.
- **Health check endpoints and structured logs** for every service, ready for monitoring.
- **Production** starts with Docker Compose on one server, and the design must allow a move to multiple servers or Kubernetes (upstream Helm charts exist) without code changes.

## Roadmap (phases)

0. **Dev environment**: get Neurvo running on the Mac with `bin/compose`, seed demo data, and document the exact steps in `docs/neurvo/DEVELOPMENT.md`.
1. **Branding**: logo and favicon drop-in, application title, user-facing name changes, emails, PDF exports, About page credit to OpenProject.
2. **Theme**: Neurvo Light and Dark (see above).
3. **Simplify**: hide the features listed above by default; clean up the menus.
4. **Integration foundation**: audit upstream extension points; create `modules/neurvo/` with the provider registry, external links, the admin Integrations page, link previews, the event publishing, and inbound webhooks. Set up Keycloak for single sign-on in development. Prove it works with a small "generic URL link preview" provider.
5. **Jira-like features**: from the list above, one at a time, each API-first.
6. **Docmost**: `modules/neurvo_docmost/` on the framework from phase 4, as described above.
7. **Production readiness**: Docker Compose for production with a reverse proxy, HTTPS, object storage, backups, SMTP, single sign-on, monitoring, and a staging environment.
8. **More integrations**: from the candidate list, prioritised with the team.

## Git

- Work on the `neurvo` branch. Keep `upstream` pointing to `https://github.com/opf/openproject.git` for future merges.
- Commit messages: `neurvo(<area>): <summary>`, for example `neurvo(branding): replace logo and favicon`.
- Never force-push or rewrite history unless I ask.
- The clone is shallow (`--depth 1`). Before merging a future upstream release, fetch more history first (for example `git fetch --deepen=500 upstream`).
