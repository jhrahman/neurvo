# Running Neurvo locally (macOS, Docker)

Tested target: MacBook Air (Apple Silicon), Docker Desktop with about 8 GB of memory.

## One-time setup

1. Install Docker Desktop (`brew install --cask docker`), start it, and set Resources > Memory to 8 GB.
2. From the repo root:

   ```bash
   cp docker-compose.override.example.yml docker-compose.override.yml   # publishes ports 3000 and 4200
   bin/compose setup      # installs gems and npm packages into volumes (first run takes a while)
   bin/compose run        # starts db, cache, frontend (background) and backend (foreground)
   ```

   `config/database.yml` must not exist (it doesn't in this repo).
3. In a second terminal, create the schema and demo data:

   ```bash
   bin/compose exec backend bundle exec rails db:migrate db:seed
   ```
4. Open <http://localhost:3000> and log in as `admin` / `admin` (you are asked to change the password).

## Daily use

| Task | Command |
|---|---|
| Start everything in the background | `bin/compose start` |
| Follow backend logs | `bin/compose logs -f backend` |
| Stop | `bin/compose stop` |
| Run specs | `bin/compose rspec spec/models/setting_spec.rb` |
| Rails console | `bin/compose exec backend bundle exec rails console` |
| Wipe everything (needs `setup` again) | `bin/compose reset` |

Do not start the optional services in `docker/dev/` (Keycloak, Nextcloud, GitLab, MinIO and so on) unless a task needs them.
The frontend dev server (Angular) is slow on the first compile; wait until the backend log shows the page can be served.
