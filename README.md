# Neurvo

**The taste of Jira, for free.** Neurvo is Ocean IT Solutions' project management and ticketing platform for software, QA and DevOps teams: issues, Jira-style boards, sprints, releases, a roadmap, wiki and meetings in one self-hosted tool.

Neurvo is a customized and improved fork of [OpenProject](https://www.openproject.org) 17.9.6 (GPLv3). Everything OpenProject offers still works; Neurvo makes the everyday dev/QA path simpler and nicer.

## What's different from OpenProject

- **Jira-style boards**: compact cards with type badge, issue key, story points, due date, priority and avatar; blocked cards are flagged; columns show counts.
- **Dev/QA workflow out of the box**: types Epic, Story, Task, Sub-task, Bug, Feature Request, Change Request, Support Request and Milestone; statuses To Do, In Progress, In Review, Ready for QA, In QA, Done (plus Reopened, Blocked, Waiting on Customer, Won't Do); readable issue keys such as `GOFLEET-15`; bug and support fields and description templates.
- **Readable status colors**: solid color with bold white text.
- **Modern Home page** with your work, active sprints, recent activity and an overview.
- **Create without friction**: the project is pre-selected with a short hint instead of a blocking notice.
- **In-app confirmations** instead of browser pop-ups.
- **Sample workspace** (GoFleet, QuickCart, Platform & DevOps, Neurvo) with boards, sprints, releases, wiki and meetings, so a new team can see the flow immediately.
- **Share a local instance** through a tunnel with `bin/neurvo-share`.
- Branding as Neurvo / Ocean IT Solutions. Enterprise-only features are neither unlocked nor bypassed.

The full list of changes to upstream files is in [docs/neurvo/CHANGES.md](docs/neurvo/CHANGES.md).

## Run it on your computer (Mac or Windows)

You need **Docker Desktop**, about 8 GB of memory for it (10 to 12 GB is more comfortable), 20 GB free disk space and Git. The first setup takes 15 to 30 minutes.

### Mac

```bash
brew install --cask docker        # then start Docker Desktop (Settings > Resources > Memory: 8 GB or more)
git clone <your-neurvo-repo-url> neurvo && cd neurvo
git checkout neurvo
```

### Windows

1. Install [Docker Desktop](https://www.docker.com/products/docker-desktop/) with the **WSL 2** backend and [WSL](https://learn.microsoft.com/windows/wsl/install) (`wsl --install` in an admin PowerShell, then restart).
2. In Docker Desktop: Settings > Resources > WSL integration, enable your Ubuntu distro; give it 8 GB or more of memory.
3. Open the **Ubuntu** terminal and run everything below there. Clone **inside the Linux file system** (for example `~/neurvo`), not under `/mnt/c`, otherwise it is very slow.

```bash
git clone <your-neurvo-repo-url> neurvo && cd neurvo
git checkout neurvo
```

### Then, on both

```bash
docker network create gateway
cp docker-compose.override.example.yml docker-compose.override.yml
bin/compose setup                  # builds, installs, migrates, seeds (15-30 min, once)
bin/compose start
bin/compose up -d backend worker
bin/compose exec backend bundle exec rake neurvo:seed    # optional: the sample workspace
```

Open <http://localhost:3000> and sign in as `admin` / `admin` (you are asked to change the password). With the sample workspace, the team members (for example `imran.chowdhury`, `daniel.brooks`, `nusrat.jahan`) use the password `Neurvo-Dev-2026!`.

Daily use: `bin/compose start && bin/compose up -d backend worker` to start, `bin/compose stop` to stop. If a page looks unstyled, the frontend dev server ran out of memory: `bin/compose up -d frontend`. More tips, running specs and sharing your local copy: [docs/neurvo/DEVELOPMENT.md](docs/neurvo/DEVELOPMENT.md).

## Deploy to a server

Production uses Docker Compose on a Linux server (Ubuntu 22.04+ is fine): 4 vCPU, 8 GB RAM and 40 GB disk are a good start for about 100 users. Full guide, including backups and updates: [docs/neurvo/DEPLOY.md](docs/neurvo/DEPLOY.md).

```bash
# 1. On the server: install Docker, point a DNS name (e.g. neurvo.yourcompany.com) at it, open ports 80 and 443
curl -fsSL https://get.docker.com | sh

# 2. Get the code and configure
git clone <your-neurvo-repo-url> neurvo && cd neurvo && git checkout neurvo
cp .env.prod.example .env.prod
nano .env.prod                      # set NEURVO_HOST, POSTGRES_PASSWORD, SECRET_KEY_BASE (openssl rand -hex 64)

# 3. Build and start (the first build takes 20-40 minutes)
docker compose --env-file .env.prod -f docker-compose.prod.yml up -d --build
```

Open `https://<your host>`; HTTPS certificates are issued automatically. Sign in as `admin` / `admin` and change the password immediately.

## Documentation

- [NEURVO.md](NEURVO.md): product vision, guardrails and conventions for contributors
- [docs/neurvo/DEVELOPMENT.md](docs/neurvo/DEVELOPMENT.md): local development
- [docs/neurvo/DEPLOY.md](docs/neurvo/DEPLOY.md): production deployment
- [docs/neurvo/CHANGES.md](docs/neurvo/CHANGES.md): changes to upstream files, to keep merging upstream updates easy
- OpenProject's own [user guide](https://www.openproject.org/docs/user-guide/) applies to everything Neurvo inherits

## License and credits

Neurvo is based on [OpenProject](https://www.openproject.org) and, like it, is licensed under the GNU GPL v3; see [COPYRIGHT](COPYRIGHT) and [LICENSE](LICENSE). Many thanks to the OpenProject community.
