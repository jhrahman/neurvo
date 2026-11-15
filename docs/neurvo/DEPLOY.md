# Deploy Neurvo to a server

This guide takes you from an empty Linux server to a running Neurvo with HTTPS, step by step. Copy and paste the commands in order.
It uses Docker Compose on a single machine: PostgreSQL, a cache, the Neurvo web app, a background worker and Caddy, which gets a free
HTTPS certificate for you ([docker-compose.prod.yml](../../docker-compose.prod.yml)).

> **Please read:** the production stack has been checked with `docker compose config` only. The first full build on a server has not
> been trial-run yet. Try it on a test server before you put real data on it.

## Before you start

| You need | Details |
|---|---|
| **A Linux server** | Ubuntu 22.04 or newer, x86_64. About **4 CPUs, 8 GB RAM and 40 GB disk** for a team of around 100. This is a sizing estimate, not a measured figure |
| **A domain name** | For example `neurvo.yourcompany.com`, with an **A record** pointing to the server's IP address |
| **Open ports** | **80 and 443** (the certificate needs both) and 22 for SSH. Nothing else needs to be open |
| **An email account (SMTP)** | Optional, but needed for invitations, password resets and notifications. You can add it later |

## Step by step

### Step 1. Log in to the server and install Docker

```bash
ssh your-user@your-server-ip
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER      # then log out and log in again
docker compose version             # should print a version number
```

### Step 2. Download Neurvo

```bash
git clone https://github.com/jhrahman/neurvo.git
cd neurvo
git checkout neurvo
```

### Step 3. Create your settings file

```bash
cp .env.prod.example .env.prod
```

Generate the two secrets with one command each:

```bash
sed -i "s/^POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$(openssl rand -hex 24)/" .env.prod
sed -i "s/^SECRET_KEY_BASE=.*/SECRET_KEY_BASE=$(openssl rand -hex 64)/" .env.prod
```

Now open the file (`nano .env.prod`) and fill in the rest:

| Setting | What to put |
|---|---|
| `NEURVO_HOST` | Your domain name, for example `neurvo.yourcompany.com`. No `https://` |
| `NEURVO_ADMIN_EMAIL` | The email of the first administrator |
| `NEURVO_ADMIN_PASSWORD` | A long, unique password for the first administrator. Avoid the characters `$`, `"` and `'` |
| `POSTGRES_PASSWORD`, `SECRET_KEY_BASE` | Already filled in by the commands above. **Keep a copy in your password manager.** Losing the secret key breaks sessions and stored secrets |

Save the file (in nano: Ctrl+O, Enter, Ctrl+X), then make it readable by you only:

```bash
chmod 600 .env.prod
```

`.env.prod` is ignored by Git, so it is never uploaded. Only the one-time `seeder` container receives the administrator password.

### Step 4. Build and start

```bash
./bin/neurvo-prod up -d --build
```

The first build takes **20 to 40 minutes** and needs about 8 GB of memory. On a smaller server, add swap first. To watch progress:

```bash
./bin/neurvo-prod logs -f seeder web
```

Press Ctrl+C to stop watching (Neurvo keeps running). The `seeder` container sets up the database and creates the administrator,
then `web` starts. When `./bin/neurvo-prod ps` shows `web` as **healthy**, it is ready.

> `./bin/neurvo-prod` is a small shortcut for `docker compose --env-file .env.prod -f docker-compose.prod.yml`. Every command in
> this guide uses it.

### Step 5. Open it and sign in

Go to `https://your-domain`. The certificate is issued automatically the first time, so give it a minute.

Sign in with the login **`admin`** and the password you put in `NEURVO_ADMIN_PASSWORD`.

### Step 6. Load the Neurvo setup

Choose one.

**A. For a real team (recommended)**: the Neurvo workflow, issue types, fields and roles, without any people or projects.

```bash
./bin/neurvo-prod exec web bundle exec rake neurvo:seed CONFIG_ONLY=1
```

It sets up the statuses (To Do, In Progress, In Review, Ready for QA, In QA, Done and more), the issue types (Epic, Story, Task,
Sub-task, Bug, Feature Request, Change Request, Support Request, Milestone), bug and support fields, priorities, workflows and the
six roles (Project Manager, Developer, QA Engineer, DevOps Engineer, Designer, Team Member). It is safe to run again.

**B. For a demo or trial**: also creates four sample projects and 15 sample accounts with public passwords.

```bash
./bin/neurvo-prod exec web bundle exec rake neurvo:seed
```

Never use this on a server with real data, and remove those accounts before real use.

### Step 7. Set up your workspace

1. **Administration > System settings**: set your organization name, language and time zone.
2. **Administration > Emails and notifications**: add your SMTP details, so people receive invitations and password resets.
3. **Administration > Users and permissions > Users**: invite your people and give each one a role from [ROLES.md](ROLES.md). The Home
   page cards and permissions follow the role.
4. **Administration > Issues > Issue fields**: choose which fields each issue type shows. Create custom fields there too.
5. Create your first project and your first issue.

## Check that it works

- [ ] `https://your-domain` opens with a valid HTTPS lock
- [ ] You can sign in as `admin`
- [ ] `./bin/neurvo-prod ps` shows `web` as healthy and `worker` running
- [ ] A test email (for example **Send password reset** on a user) arrives
- [ ] You can create an issue and assign it

## Back up your data (do this on day one)

Two things hold your data: the database and the uploaded files.

```bash
mkdir -p ~/neurvo-backups
./bin/neurvo-prod exec -T db pg_dump -U neurvo neurvo | gzip > ~/neurvo-backups/neurvo-$(date +%F).sql.gz
docker run --rm -v neurvo_assets:/data -v ~/neurvo-backups:/backup alpine tar czf /backup/assets-$(date +%F).tgz -C /data .
```

The volume is named after the folder, so `neurvo_assets` assumes you cloned into a folder called `neurvo`. Check with
`docker volume ls`. Run both commands every day (for example from `crontab -e`), and **copy the files off the server**.

**To restore**, start Neurvo on a fresh server, then load the dump with `psql` into an empty database and untar the assets into the
volume. Test a restore once, before you need it.

## Update Neurvo

```bash
cd neurvo
# take a backup first (see above)
git pull
./bin/neurvo-prod up -d --build
```

Database changes run automatically through the `seeder` container. When you merge a new OpenProject release into Neurvo,
[CHANGES.md](CHANGES.md) lists every upstream file Neurvo changed, so you know where to expect conflicts.

## Everyday commands

| I want to | Run |
|---|---|
| See what is running | `./bin/neurvo-prod ps` |
| Read the logs | `./bin/neurvo-prod logs -f web worker` |
| Restart | `./bin/neurvo-prod restart web worker` |
| Open a Rails console | `./bin/neurvo-prod exec web bundle exec rails console` |
| Stop (keeps your data) | `./bin/neurvo-prod down` |
| **Delete all data too** | `./bin/neurvo-prod down -v`. This cannot be undone |

## If something goes wrong

| What you see | What to check |
|---|---|
| The site does not load over HTTPS | The domain's A record points to this server, and ports 80 and 443 are open. Look at `./bin/neurvo-prod logs proxy` |
| `NEURVO_HOST ... Set ... in .env.prod` when starting | A required line in `.env.prod` is empty. Fill it in and run Step 4 again |
| `web` keeps restarting | `./bin/neurvo-prod logs seeder web`. The usual cause is a wrong `POSTGRES_PASSWORD` or a missing `SECRET_KEY_BASE` |
| Sign-in with `admin` fails | The administrator is created only the **first** time the database is set up, so changing `NEURVO_ADMIN_PASSWORD` later has no effect. To set a new password: `./bin/neurvo-prod exec web bundle exec rails runner 'User.find_by(login: "admin").update!(password: "NEW-LONG-PASSWORD", password_confirmation: "NEW-LONG-PASSWORD")'` |
| The build is killed | The server ran out of memory. Add swap, or build on a larger machine |
| No emails arrive | SMTP is not set up under Administration > Emails and notifications |
| Home cards show zeros | Normal on an empty instance. They fill up as people create and assign work |

## Settings you may want to change

Put these in `.env.prod`, then run `./bin/neurvo-prod up -d` again.

| Setting | Default | Meaning |
|---|---|---|
| `NEURVO_WEB_WORKERS` | `1` | Web processes. Each costs roughly 500 MB to 1 GB. One worker with 16 threads is enough for about 100 people |
| `NEURVO_JOB_THREADS` | `5` | Threads the background worker uses |

The stack is tuned to stay small: one web process, a 64 MB cache, container logs rotated at 3 x 10 MB, and finished background
jobs kept for 2 days. The `cron` container only reads incoming email, so it is off by default. To turn incoming email into issues,
set the `IMAP_*` variables on it and start it with `./bin/neurvo-prod --profile imap up -d`.

More options go on the `web` and `worker` services in `docker-compose.prod.yml` as environment variables:

| Variable | Default | Meaning |
|---|---|---|
| `OPENPROJECT_NEURVO__OPEN__USER__DIRECTORY` | `true` | Every signed-in user can see every other user, so profile cards and mentions always work. `false` shows only people who share a project |
| `OPENPROJECT_HIDE__ENTERPRISE__FEATURES` | `true` | Hides Enterprise-only features and banners. Nothing is unlocked or bypassed |
| `OPENPROJECT_SHOW__COMMUNITY__LINKS` | `false` | Shows or hides links to the OpenProject community |

## Good to know

- Real-time collaborative editing in the wiki needs the Hocuspocus service, which this stack does not run. Everything else works without it.
- Never expose the database or cache ports to the internet.
- Keep `.env.prod` out of Git (it is ignored) and keep a copy in your password manager.
