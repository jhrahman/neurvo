# Preset avatars

32 ready-made avatars for people who do not want to upload a picture. They are original flat illustrations
(varied skin tones, hair, glasses, beards, hijab, backgrounds) drawn by `generate_svgs.py`.

- `svg/` vector sources, `png/` the 128x128 images that become the user's avatar, `presets.json` the list (key and label).
- Users pick one under *My account > Avatar > Or choose one of our avatars*. An administrator can do the same from a
  user's edit page. The choice is stored as the user's normal avatar, so it shows everywhere (API, boards, comments,
  mentions) and can be removed with *Delete* or replaced by uploading a photo.
- `lib/neurvo/seed_data.yml` pre-selects one for each sample account (`avatar:`).

## Change or add avatars

1. Edit the `AVATARS` table in `generate_svgs.py` and run `python3 lib/neurvo/avatars/generate_svgs.py`.
2. Render each SVG to a 128x128 transparent PNG with the same name in `png/` (for example in a browser, screenshotting
   each SVG with a transparent background).
3. Keep keys in the form `avatar-NN` (two digits): the picker route only accepts that pattern.
