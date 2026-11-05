# Deploying Neurvo to a server

This guide takes you from an empty Linux server to a running Neurvo with HTTPS. It uses Docker Compose on a single machine:
PostgreSQL, memcached, the Neurvo web app, a background worker, a cron job and Caddy for automatic HTTPS
([docker-compose.prod.yml](../../docker-compose.prod.yml)).

> The production stack has been validated with `docker compose config` only. Do a trial run on a staging server before you move
> real data.

## What you need

| Item | Recommended |
|---|---|
| Server | Linux x86_64, Ubuntu 22.04 or newer, 4 vCPU, 8 GB RAM, 40 GB disk (about 100 users) |
| Network | A DNS name that points to the server, with ports **80 and 443** open (Let's Encrypt needs both) |
| Software | Docker with the Compose plugin, Git |
| Mail (optional but advised) | An SMTP account, so invitations, password resets and notifications are sent |

## 1. Install

```bash
curl -fsSL https://get.docker.com | sh
git clone <your-neurvo-repo-url> neurvo && cd neurvo && git checkout neurvo
cp .env.prod.example .env.prod
```

Edit `.env.prod`:

| Variable | Meaning |
|---|---|
| `NEURVO_HOST` | Public host name, for example `neurvo.yourcompany.com` (no `https://`) |
| `POSTGRES_PASSWORD` | A strong password. Generate one with `openssl rand -hex 24` |
| `SECRET_KEY_BASE` | `openssl rand -hex 64`. Keep it forever: losing it invalidates sessions and stored secrets |
| `NEURVO_VERSION` | Image tag. `latest` by default; use a release tag to pin a version |

Build and start:

```bash
docker compose --env-file .env.prod -f docker-compose.prod.yml up -d --build
docker compose --env-file .env.prod -f docker-compose.prod.yml logs -f seeder web
```

The first build takes 20 to 40 minutes and needs about 8 GB of memory (add swap on small servers). The `seeder` container migrates
the database and creates the default data, and `web` starts after it finishes. When the log shows the web app is healthy, open
`https://<NEURVO_HOST>`. HTTPS certificates are issued automatically.

## 2. Sign in and secure it

1. Sign in as `admin` / `admin`. You are asked to change the password: do it now, with a long password.
2. Administration > System settings: set the organization name, default language and time zone.
3. Administration > Emails and notifications: configure SMTP.
4. Create real users (or connect single sign-on) and keep the administrator account for the people who run the system.

## 3. Choose how to start your data

OpenProject ships with its own generic defaults. Neurvo adds its workflow, ticket types, fields and roles on top, through one
command. Pick one of the two options.

**A. Neurvo setup, no sample data (a real team)**

```bash
docker compose --env-file .env.prod -f docker-compose.prod.yml exec web \
  bundle exec rake neurvo:seed CONFIG_ONLY=1
```

This sets up the Neurvo statuses (To Do, In Progress, In Review, Ready for QA, In QA, Done and more), types (Epic, Story, Task,
Sub-task, Bug, Feature Request, Change Request, Support Request, Milestone), bug and support fields, priorities, workflows and
the six roles (Project Manager, Developer, QA Engineer, DevOps Engineer, Designer, Team Member). It creates no users and no
projects, and it is safe to run again. Then create your projects and invite your people, giving each one a role from
[ROLES.md](ROLES.md): the Home page cards and permissions follow the role.

**B. Sample company (a demo or a trial)**

```bash
docker compose --env-file .env.prod -f docker-compose.prod.yml exec web bundle exec rake neurvo:seed
```

This also creates four sample projects and 15 sample accounts with public passwords ([USERS.md](USERS.md)). Never use it on an
instance with real data, and delete or disable those accounts before real use.

## Settings you may want to change

Set these as environment variables on the `web` and `worker` services (the Compose file already hides Enterprise banners).

| Variable | Default | Meaning |
|---|---|---|
| `OPENPROJECT_NEURVO__OPEN__USER__DIRECTORY` | `true` | Every signed-in user can see every other user, so profile cards and mentions always work. Set `false` to show only people who share a project |
| `OPENPROJECT_HIDE__ENTERPRISE__FEATURES` | `true` | Hides Enterprise-only features and banners. Nothing is unlocked or bypassed |
| `OPENPROJECT_SHOW__COMMUNITY__LINKS` | `false` | Shows or hides links to the OpenProject community |

## Backups

```bash
# database
docker compose --env-file .env.prod -f docker-compose.prod.yml exec -T db pg_dump -U neurvo neurvo | gzip > neurvo-$(date +%F).sql.gz
# attachments
docker run --rm -v neurvo_assets:/data -v "$PWD":/backup alpine tar czf /backup/assets-$(date +%F).tgz -C /data .
```

The volume prefix `neurvo_` is the folder name; check with `docker volume ls`. Run both daily from cron and copy the files off the
server. To restore, load the dump with `psql` into an empty database and untar the assets into the volume.

## Updating

```bash
git pull
docker compose --env-file .env.prod -f docker-compose.prod.yml up -d --build
```

Take a backup first. Migrations run automatically through the `seeder` container. When you merge a new OpenProject release into
Neurvo, [CHANGES.md](CHANGES.md) lists every upstream file Neurvo changed, so you know where to expect conflicts.

## Day-to-day operations

All commands use the prefix `docker compose --env-file .env.prod -f docker-compose.prod.yml`.

| Task | Command |
|---|---|
| Status | `ps` |
| Logs | `logs -f web worker` |
| Restart | `restart web worker` |
| Rails console | `exec web bundle exec rails console` |
| Stop | `down` (add `-v` only if you want to delete all data) |

## Troubleshooting

| Symptom | What to check |
|---|---|
| The site does not load over HTTPS | The DNS name points to this server and ports 80 and 443 are open. Look at `logs proxy` |
| `web` keeps restarting | `logs seeder web`. The most common causes are a wrong `POSTGRES_PASSWORD` or a missing `SECRET_KEY_BASE` |
| The build is killed | The server ran out of memory. Add swap or use a bigger machine for the build |
| No emails arrive | SMTP is not configured under Administration > Emails and notifications |
| Home cards show zeros | Normal on an empty instance. They fill up as people create and assign work |

## Notes

- Real-time collaborative editing in the wiki needs the Hocuspocus service, which this stack does not run. Everything else works
  without it.
- Do not expose the database or memcached ports.
- Keep `.env.prod` out of Git (it is ignored) and keep a copy in your password manager.
