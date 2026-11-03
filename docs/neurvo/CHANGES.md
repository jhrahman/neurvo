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
