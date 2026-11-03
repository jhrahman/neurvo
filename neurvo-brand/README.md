# Neurvo logo files (concept A: "Node Check")

Colors: blue `#1276B9`, green `#8DC543`, white `#FFFFFF`.
Font: Saira Semi Condensed 500. In these files the lettering is already turned into shapes, so the font doesn't need to be installed.

## Folders

- `svg/`: master files. Edit these, then re-export any PNGs from them.
  - `neurvo-logo.svg` / `neurvo-logo-white.svg`: horizontal logo (mark + NEURVO)
  - `neurvo-logo-stacked.svg`: mark above the name
  - `neurvo-mark.svg` / `neurvo-mark-white.svg`: symbol only
  - `neurvo-app-icon.svg`: rounded square app icon
  - `neurvo-favicon.svg`: simplified icon for very small sizes (no dots)
- `png/`: large PNGs for slides, docs, chat avatars and similar.
- `openproject-dropin/`: replacement files with **the same names, paths and pixel sizes** as OpenProject v17.9.6. Copy them over the originals in the repo root.

## Drop-in files

| File in the OpenProject repo | Replaced with |
|---|---|
| `app/assets/images/logo_openproject.png` (700×150) | Blue horizontal logo |
| `app/assets/images/logo_openproject_white_big.png` (600×113) | White horizontal logo, used on the blue header |
| `app/assets/images/logo-white-bg-ua.png` (1000×238) | Blue horizontal logo |
| `app/assets/images/logo-black-bg-ua.png` (1000×238) | White horizontal logo |
| `app/assets/images/icon_logo.svg` | Blue mark |
| `app/assets/images/icon_logo_white.svg` | White mark |
| `app/assets/images/logo_openproject_narrow.svg` (82×82) | App icon |
| `app/assets/images/apple-touch-icon-120x120.png` | App icon |
| `app/assets/images/favicon.ico`, `public/favicon.ico` | Favicon (16, 32, 48 px) |
| `docker/prod/logo.png` (150×150) | App icon |

Not replaced: `app/assets/images/development/*` (the dev-mode favicon) and `modules/bim/...` (the BIM edition's logos).

## Prompt for Claude Code

> Copy everything in `neurvo-brand/openproject-dropin/` over the matching paths in this repo. Then find anywhere else the OpenProject logo or favicon is referenced (CSS, ERB views, PDF exports, mail templates) and make sure the Neurvo files are used. Commit the changes on the `neurvo` branch.
