# Neurvo changes to core (non-`modules/neurvo`) files

Every upstream file changed by Neurvo is listed here with a one-line reason, to ease merging upstream releases.

## Branding

| File | Reason |
|---|---|
| `app/assets/images/logo_openproject.png` | Neurvo blue horizontal logo (same name and size) |
| `app/assets/images/logo_openproject_white_big.png` | Neurvo white logo for the blue header |
| `app/assets/images/logo-white-bg-ua.png` | Neurvo blue logo |
| `app/assets/images/logo-black-bg-ua.png` | Neurvo white logo |
| `app/assets/images/icon_logo.svg` | Neurvo blue mark |
| `app/assets/images/icon_logo_white.svg` | Neurvo white mark |
| `app/assets/images/logo_openproject_narrow.svg` | Neurvo app icon |
| `app/assets/images/apple-touch-icon-120x120.png` | Neurvo app icon |
| `app/assets/images/favicon.ico`, `public/favicon.ico` | Neurvo favicon |
| `docker/prod/logo.png` | Neurvo app icon |

## User-facing names ("OpenProject" → "Neurvo")

Replaced in values only (never keys or identifiers). Kept on purpose: "OpenProject Enterprise", "OpenProject GmbH",
"OpenProject community/blog/website", version numbers (e.g. "OpenProject 16.0"), the upstream release database,
and the Nextcloud/XWiki "OpenProject integration" app names, which are third-party names.

| File | Reason |
|---|---|
| `config/locales/en.yml`, `config/locales/js-en.yml` | UI strings say Neurvo |
| `modules/*/config/locales/en.yml`, `modules/*/config/locales/js-en.yml` | Same, per module |
| `config/constants/settings/definition.rb` | Default `app_title` is "Neurvo" (still overridable in admin or `OPENPROJECT_APP__TITLE`) |
| `app/views/user_mailer/test_mail.{html,text}.erb` | Hard-coded product name in test mail |
| `spec/models/setting_spec.rb`, `spec/controllers/external_link_warning_controller_spec.rb` | Follow the renamed strings |

## Dev environment and seed data

| File | Reason |
|---|---|
| `docker-compose.yml` | `OPENPROJECT_DEVELOPMENT__HIGHLIGHT__ENABLED` defaults to `false` so the header no longer shows the "development" stripe text |
| `app/seeders/standard.yml` | Neurvo welcome title and text (no openproject.org marketing links); "get started in Neurvo" |

## Theme

| File | Reason |
|---|---|
| `app/views/my/_color_mode_menu.html.erb` (new) | One-click Light/Dark switch in the avatar menu; posts to the existing `PATCH /my/settings`, so no new route or API |
| `config/initializers/menus.rb` | Registers the `:color_mode` partial item in the account menu |
| `spec/views/my/color_mode_menu_spec.rb` (new) | Covers the menu partial |

Default stays Light (`user_default_theme = light`). Each user can switch any time from the avatar menu or Account settings > Interface.

## Toasts

| File | Reason |
|---|---|
| `frontend/src/global_styles/neurvo/` (new) | Neurvo-only styles; first file moves Rails flash and Angular toasts to the bottom-right with a slide-in |
| `frontend/src/global_styles/openproject.sass` | Imports `neurvo/_index.sass` |
| `frontend/src/stimulus/controllers/flash.controller.ts`, `frontend/src/app/shared/components/toaster/toast.service.ts` | Success toasts auto-hide after 4 s instead of 5 s. Errors and warnings stay until dismissed |

## Header

| File | Reason |
|---|---|
| `lib/redmine/menu_manager/top_menu/quick_add_menu.rb` | Header "+" button now reads "Create" (Jira-style) with the same dropdown |

## Loader

| File | Reason |
|---|---|
| `frontend/src/global_styles/neurvo/_loader.sass` (new) | Animated Neurvo mark replaces the green-squares loader (`.op-loading-indicator`) and the global Primer spinner. CSS-only, light/dark variants, honours reduced motion. Turbo progress bar uses the brand gradient |

## Hiding Enterprise-only (premium) features

Hide only: token checks are untouched and the code stays. An admin can show everything again with
`OPENPROJECT_HIDE__ENTERPRISE__FEATURES=false`, `OPENPROJECT_EE__HIDE__BANNERS=false`, `OPENPROJECT_EE__MANAGER__VISIBLE=true`
and `OPENPROJECT_SHOW__COMMUNITY__LINKS=true`. `define_custom_style` (Design page) stays reachable for the theme settings.

| File | Reason |
|---|---|
| `docker-compose.yml` | Dev defaults for the four env vars above (banners, Enterprise admin page, community/"New features" blocks) |
| `config/constants/settings/definition.rb` | New setting `hide_enterprise_features` (default true) |
| `lib/redmine/menu_manager/menu_item.rb` | `enterprise_feature_hidden?`; exempt list; no upsell badge for exempt features |
| `lib/redmine/menu_manager/menu_helper.rb` | `visible_node?` skips hidden Enterprise entries (global, project, admin, module menus) |
| `lib/redmine/menu_manager/top_menu/help_menu.rb` | Help-menu "Upgrade" link follows `ee_hide_banners` |
| `lib/open_project/menu.rb` | Submenu groups drop items flagged with the Enterprise icon (work package "Shared with…", meeting templates) |
| `spec/lib/redmine/menu_manager/menu_item_enterprise_spec.rb`, `spec/lib/open_project/menu/menu_group_spec.rb` (new) | Cover the above |

## Palettes (light and dark variations)

Each user picks a palette per color mode: Light = Neurvo Light (default), Warm, Paper, Solarized Light;
Dark = Neurvo Dark (default), Ash, Pure black, One Dark Pro, Dracula, Tokyo Night. All text pairs checked at 4.5:1 or better.

| File | Reason |
|---|---|
| `frontend/src/global_styles/neurvo/_palettes.sass` (new) | Palettes as Primer token overrides keyed by `data-neurvo-light-palette` / `data-neurvo-dark-palette`; also swatch styles |
| `config/schemas/user_preferences.schema.json` | New preference properties `light_palette`, `dark_palette` |
| `app/models/user_preference.rb` | Palette lists and getters with fallback to `default` |
| `app/models/permitted_params.rb` | Permits the two palette params |
| `app/helpers/application_helper.rb` | Emits the palette `data-` attributes on `<body>` |
| `app/forms/my/look_and_feel_form.rb` | Light/Dark palette selects on Account settings > Interface |
| `app/views/my/_color_mode_menu.html.erb` | Palette swatches in the avatar menu |
| `config/locales/en.yml` | Palette names and labels |
| `spec/models/user_preference_spec.rb`, `spec/views/my/color_mode_menu_spec.rb` | Cover palettes |

## Keyboard

| File | Reason |
|---|---|
| `frontend/src/app/shared/directives/a11y/keyboard-shortcut.service.ts` | `⌘K` / `Ctrl+K` focuses global search (browser default prevented); `c` opens the Create menu (Jira-style) |
| `lib/redmine/menu_manager/top_menu/user_menu.rb`, `app/views/my/_color_mode_form.html.erb` (new) | Color mode form rendered outside the user-menu dialog so an outside click closes the panel (Primer keeps dialogs containing a form open) |

## Sample workspace

New files only: `lib/neurvo/seed.rb`, `lib/neurvo/seed_data.yml`, `lib/tasks/neurvo.rake` (`rake neurvo:seed`).
It switches the instance to semantic issue keys, renames/creates statuses, types and priorities, adds bug fields and
roles, rebuilds workflows, and creates the team, projects, sprints, releases, issues, boards and saved views.

## Global Create (Jira-style)

| File | Reason |
|---|---|
| `lib/redmine/menu_manager/top_menu/quick_add_menu.rb` | Create lists the types of every project the user can add to and always opens the global form, preselecting the current project |
| `app/views/work_packages/new.html.erb`, `app/components/work_packages/full_view/create_component.{rb,html.erb}` | Pass `default_project` to the create form |
| `frontend/src/app/features/work-packages/routing/wp-full-create/wp-full-create-entry.component.ts`, `frontend/src/app/features/work-packages/components/wp-new/wp-create.component.ts` | Preselect the default project in the global create form (still changeable) |
| `spec/features/menu_items/quick_add_menu_spec.rb` | Follows the new behaviour (feature spec; needs a browser, not run on Apple Silicon) |
| `frontend/src/app/core/enterprise/banners.service.ts`, `frontend/src/app/features/work-packages/components/wp-buttons/wp-share-button/*` | Hide the work package share button when sharing is Enterprise-only and banners are hidden |

## Motion and privacy

| File | Reason |
|---|---|
| `frontend/src/global_styles/neurvo/_motion.sass` (new) | Consistent 120–200 ms transitions on controls, card lift on boards, slide-in side panels, pop-in menus; off with reduced motion. Cross-document view transitions were tried and dropped: they conflict with Turbo |
| `lib/neurvo/seed.rb` | Gravatar disabled (no hashed staff e-mails sent to gravatar.com); uploaded avatars and initials remain |
| `lib/redmine/menu_manager/top_menu/help_menu.rb`, `config/locales/en.yml` | With `show_community_links` off, the help menu keeps User guides, Shortcuts and API docs, drops vendor/community links and credits OpenProject |
| `frontend/src/app/features/work-packages/components/wp-fast-table/builders/primary-render-pass.ts` | Upstream bug: refreshing a row that is not in this table crashed (My page with the same work package in two widgets). Early return when the row is missing |
| `config/initializers/homescreen.rb` | News block only when some project uses the News module |
| `lib/neurvo/seed.rb` | Members star their projects (Favorite projects on Home) |
| `modules/meeting/app/components/meetings/widgets/meetings.rb`, its spec | Upstream bug: "My meetings" listed meeting-series templates next to the real occurrences |
| `lib/neurvo/seed.rb`, `lib/neurvo/seed_data.yml` | Team rituals: daily stand-up, weekly bug triage (with critical bugs on the agenda), sprint review & retro, sprint planning, release go/no-go; team time zone Asia/Dhaka |
| `docker-compose.yml` | `OPENPROJECT_ONBOARDING__ENABLED=false`: the upstream tour walks through demo projects that Neurvo does not ship |
| `app/helpers/highlighting_helper.rb`, `spec/helpers/highlighting_helper_spec.rb` | Upstream bug: the type/status/priority color stylesheet was cached publicly per version tag without the color mode, so light and dark users got each other's colors (type names unreadable in dark). The tag now includes mode and contrast |
| `lib/neurvo/seed_data.yml`, `spec/lib/neurvo/seed_type_colors_spec.rb` (new) | Type colors checked at 4.5:1 or better in every light and dark palette (Sub-task teal, Milestone slate) |

## Sign-in and boards

| File | Reason |
|---|---|
| `frontend/src/global_styles/neurvo/_login.sass` (new) | Centred sign-in card with the Neurvo mark on a muted background; hides the empty "or sign in with" divider when no SSO provider renders |
| `frontend/src/global_styles/neurvo/_boards.sass` (new) | Board columns show "To Do" instead of "Status / To Do" |
| `lib/neurvo/seed.rb` | Self-registration disabled: admins invite team members |
