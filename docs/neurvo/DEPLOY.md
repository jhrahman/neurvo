# Deploying Neurvo to a server

Docker Compose on one Linux x86_64 server: PostgreSQL, memcached, the Neurvo web app, a background worker, a cron job and Caddy for HTTPS ([docker-compose.prod.yml](../../docker-compose.prod.yml)).

> The production stack has been validated with `docker compose config` only. Do a trial run on a staging server before you move real data.

## Requirements

- Ubuntu 22.04+ (or any Linux with Docker), 4 vCPU, 8 GB RAM, 40 GB disk for about 100 users.
- A DNS name pointing to the server, ports 80 and 443 open (Let's Encrypt needs both).

## First install

```bash
curl -fsSL https://get.docker.com | sh
git clone <your-neurvo-repo-url> neurvo && cd neurvo && git checkout neurvo
cp .env.prod.example .env.prod
```

Edit `.env.prod`:

| Variable | Meaning |
|---|---|
| `NEURVO_HOST` | Public host name, e.g. `neurvo.yourcompany.com` (no `https://`) |
| `POSTGRES_PASSWORD` | `openssl rand -hex 24` |
| `SECRET_KEY_BASE` | `openssl rand -hex 64`. Keep it forever; losing it invalidates sessions and stored secrets |
| `NEURVO_VERSION` | Image tag, `latest` by default |

```bash
docker compose --env-file .env.prod -f docker-compose.prod.yml up -d --build
docker compose --env-file .env.prod -f docker-compose.prod.yml logs -f seeder web
```

The first build takes 20 to 40 minutes and needs about 8 GB of memory (add swap on small servers). The `seeder` container migrates the database and creates the default data; `web` starts after it finishes. Then open `https://<NEURVO_HOST>`, sign in as `admin` / `admin` and change the password at once.

Optional sample workspace (do not use on a real instance):
`docker compose --env-file .env.prod -f docker-compose.prod.yml exec web bundle exec rake neurvo:seed`

## After the first login

- Administration > System settings: set the organization name, default language and time zone.
- Administration > Emails and notifications: configure SMTP, so invitations, password resets and notifications are sent.
- Create real users (or connect single sign-on) and remove or disable the sample accounts.

## Backups

```bash
# database
docker compose --env-file .env.prod -f docker-compose.prod.yml exec -T db pg_dump -U neurvo neurvo | gzip > neurvo-$(date +%F).sql.gz
# attachments
docker run --rm -v neurvo_assets:/data -v "$PWD":/backup alpine tar czf /backup/assets-$(date +%F).tgz -C /data .
```

(The volume prefix `neurvo_` is the folder name; check with `docker volume ls`.) Run these daily from cron and copy them off the server. To restore, load the dump with `psql` into an empty database and untar the assets into the volume.

## Updating

```bash
git pull
docker compose --env-file .env.prod -f docker-compose.prod.yml up -d --build
```

Take a backup first. Migrations run automatically through the `seeder` container.

## Operations

| Task | Command (prefix: `docker compose --env-file .env.prod -f docker-compose.prod.yml`) |
|---|---|
| Status | `ps` |
| Logs | `logs -f web worker` |
| Restart | `restart web worker` |
| Rails console | `exec web bundle exec rails console` |
| Stop | `down` (add `-v` only to delete all data) |

## Notes

- Real-time collaborative editing in the wiki needs the Hocuspocus service, which this stack does not run. Everything else works without it.
- Do not expose the database or memcached ports.
- Keep `.env.prod` out of Git (it is ignored) and keep a copy in your password manager.
