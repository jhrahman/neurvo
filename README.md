# Neurvo

**The taste of Jira, for free.** Neurvo is Ocean IT Solutions' project management and ticketing platform for software, QA and DevOps teams: issues, Jira-style boards, sprints, releases, a roadmap, wiki and meetings in one self-hosted tool.

Neurvo is a customized and improved fork of [OpenProject](https://www.openproject.org) 17.9.6 (GPLv3). Everything OpenProject offers still works; Neurvo makes the everyday dev/QA path simpler and nicer.

## Why Neurvo instead of plain OpenProject?

OpenProject is a great engine. It is also built for every kind of team, so a software team has to shape it before it feels right. Neurvo does that shaping for you. You get the same solid foundation, already tuned for the way developers, QA and DevOps actually work day to day.

Everything OpenProject can do still works. We only changed what gets in your way.

### At a glance

| | OpenProject | Neurvo |
|---|---|---|
| First look | Generic project tool | Jira-style home, boards and issue keys like `GOFLEET-15` |
| Dev and QA flow | You design it | Ready on day one: Epic to Bug, To Do to Done, with a QA gate |
| Discussion on a ticket | Activity feed | A dedicated Comments tab with threads, replies and deep links |
| Writing | Standard editor | Modern editor with real code snippets, language picker and copy button |
| People | Initials in a circle | Preset avatars, designations and click-through profile cards |
| Premium upsells | Banners everywhere | Hidden, so the app stays clean |
| Trying it out | Empty workspace | A full sample company with boards, sprints, wiki and meetings |

Open the sections below to see what each one feels like in practice.

<details>
<summary><b>Boards and tickets that look like the tools you already know</b></summary>

<br>

- Compact board cards with a type badge, issue key, story points, due date, priority and the assignee's avatar.
- Blocked cards are flagged so nobody has to hunt for them, and every column shows a count.
- Status colors are solid with bold white text, so you can read them from across the room.
- Creating a ticket is quick: the project is already selected and you get a short hint instead of a blocking notice.
- A global **Create** button in the header, just like you would expect.

</details>

<details>
<summary><b>A dev and QA workflow that works out of the box</b></summary>

<br>

- Types: Epic, Story, Task, Sub-task, Bug, Feature Request, Change Request, Support Request and Milestone.
- Statuses: To Do, In Progress, In Review, Ready for QA, In QA and Done, plus Reopened, Blocked, Waiting on Customer and Won't Do.
- Readable issue keys, bug and support fields, and description templates so tickets start with the right questions answered.
- Sample roles for Project Manager, Developer, QA Engineer, DevOps Engineer, Designer and a general Team Member, each with sensible permissions. See [ROLES.md](docs/neurvo/ROLES.md).

</details>

<details>
<summary><b>Comments that feel like a conversation</b></summary>

<br>

- **Comments is the first tab** on every ticket, followed by Files, Relations and Activity.
- Reply in threads, edit or delete your own comments, and sort by newest or oldest.
- Copy a link to any comment. Whoever opens it lands right on that comment, and it flashes yellow for a second so the eye finds it.
- Each comment shows the author's name with their designation underneath. Click the name or avatar to open a profile card.
- Submitting shows progress, and the new comment gets a quick highlight so you know it went through.
- Closing a half-written comment asks you in a proper in-app dialog, not a browser pop-up.

</details>

<details>
<summary><b>A nicer place to write</b></summary>

<br>

- A modernised rich text editor built only from free, open source parts.
- Code blocks with a language picker, a delete button and a single clean language label.
- Copy buttons on code in comments and descriptions, with a small "Copied" confirmation.
- Find and replace right inside the editor.

</details>

<details>
<summary><b>People, not just usernames</b></summary>

<br>

- 32 preset avatars to choose from under *My account*, in case you would rather not upload a photo. You can still upload your own.
- Every user can carry a designation such as "Senior Engineer", shown in the user menu and next to their comments.
- Every signed-in person can see their colleagues, so profile cards and mentions always work. If you prefer the stricter project-only visibility, one setting turns it back.

</details>

<details>
<summary><b>Easy on the eyes, and on the room</b></summary>

<br>

- Light and dark modes with extra palettes for each. Hover a swatch to see its name before you pick it.
- A refreshed header that holds up on phones, with the logo and search no longer fighting for space.
- Toasts slide in at the bottom right and success messages clear themselves.
- Calm motion that respects the reduced motion setting, and an animated Neurvo mark instead of the stock loader.
- Keyboard shortcuts for the things you do all day.

</details>

<details>
<summary><b>Clean by default</b></summary>

<br>

- Enterprise-only features are hidden, so there are no upgrade banners in your way. Nothing is unlocked or bypassed, and an admin can show them again with a setting.
- Branded as Neurvo by Ocean IT Solutions throughout.

</details>

<details>
<summary><b>Look around from the very first login</b></summary>

<br>

- A sample workspace (GoFleet, QuickCart, Platform & DevOps and Neurvo) with boards, sprints, releases, wiki pages and meetings, so a new team can feel the flow immediately.
- Ready-made test accounts for every role, listed in [USERS.md](docs/neurvo/USERS.md).
- Share your local copy with a teammate through a tunnel using `bin/neurvo-share`.

</details>

Curious about the exact files we touched? Every change to upstream code is listed in [docs/neurvo/CHANGES.md](docs/neurvo/CHANGES.md), which also keeps merging new OpenProject releases painless.

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
- [docs/neurvo/ROLES.md](docs/neurvo/ROLES.md): sample roles, permissions and logins
- [docs/neurvo/USERS.md](docs/neurvo/USERS.md): every sample user with username, password and role
- [docs/neurvo/CHANGES.md](docs/neurvo/CHANGES.md): changes to upstream files, to keep merging upstream updates easy
- OpenProject's own [user guide](https://www.openproject.org/docs/user-guide/) applies to everything Neurvo inherits

## License and credits

Neurvo is based on [OpenProject](https://www.openproject.org) and, like it, is licensed under the GNU GPL v3; see [COPYRIGHT](COPYRIGHT) and [LICENSE](LICENSE). Many thanks to the OpenProject community.
