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
| `spec/lib/open_project/hide_enterprise_menu_entries_spec.rb` (new) | Covers the above |
