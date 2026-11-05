#!/usr/bin/env python3
"""Generates the Neurvo preset avatars (flat, friendly, 128x128) as SVG files and presets.yml.

Run:  python3 lib/neurvo/avatars/generate_svgs.py
PNG versions (used as the actual avatar images) are rendered from these SVGs; see README.md.
"""
import json
import pathlib

OUT = pathlib.Path(__file__).parent

BG = ["#FFD166", "#F8B4B4", "#A8DADC", "#B8E0D2", "#CDB4DB", "#FFC8A2", "#9ED8DB", "#F9C74F", "#C3E88D", "#BDE0FE"]
SKIN = {  # base, shadow
    "light": ("#FFE0C7", "#F1C3A3"),
    "fair": ("#F8CBA6", "#E5AE88"),
    "tan": ("#E3AB7C", "#CC9166"),
    "brown": ("#BC7C52", "#A2653F"),
    "dark": ("#8D5B3C", "#774A2F"),
    "deep": ("#613A26", "#4E2D1C"),
}
HAIR = {
    "black": "#211C26", "brown": "#4A3224", "chestnut": "#7A4A2B", "auburn": "#A8502B", "blonde": "#EBC75B",
    "gray": "#B9BAC4", "white": "#ECECF2", "ginger": "#D9702E", "teal": "#2FB3A7", "pink": "#EF6F9B", "blue": "#4F8DF7",
}
CLOTH = ["#264653", "#2A9D8F", "#E76F51", "#6C63FF", "#F4A261", "#355070", "#B56576", "#457B9D", "#1D3557", "#E63946"]
INK = "#2A2230"


def hair_back(style, c):
    if style == "long":
        return f'<path d="M36 56C30 90 36 114 50 114L78 114C92 114 98 90 92 56C92 28 36 28 36 56Z" fill="{c}"/>'
    if style == "bob":
        return f'<path d="M37 54C32 80 36 92 42 92L86 92C92 92 96 80 91 54C91 28 37 28 37 54Z" fill="{c}"/>'
    if style == "afro":
        return f'<circle cx="64" cy="46" r="35" fill="{c}"/>'
    if style == "curly":
        return (f'<circle cx="64" cy="44" r="30" fill="{c}"/><circle cx="42" cy="56" r="10" fill="{c}"/>'
                f'<circle cx="86" cy="56" r="10" fill="{c}"/>')
    if style == "bun":
        return f'<circle cx="64" cy="18" r="11" fill="{c}"/>'
    if style == "ponytail":
        return f'<path d="M84 44C108 50 108 92 94 104C100 82 96 64 86 56Z" fill="{c}"/>'
    return ""


def hair_front(style, c):
    caps = {
        "short": "M39 56C34 34 50 24 64 24C80 24 94 34 89 56C87 47 83 41 76 38C68 42 54 42 48 38C43 41 41 49 39 56Z",
        "sidepart": "M39 56C33 32 52 23 66 24C82 25 94 36 89 56C88 46 84 40 76 37C66 44 52 42 46 36C42 42 41 49 39 56Z",
        "buzz": "M41 52C40 34 52 27 64 27C76 27 88 34 87 52C85 44 79 38 64 38C49 38 43 44 41 52Z",
        "long": "M40 54C38 34 50 26 64 26C78 26 90 34 88 54C84 44 76 38 64 36C52 38 44 44 40 54Z",
        "bob": "M40 52C40 34 52 27 64 27C76 27 88 34 88 52C80 44 72 42 64 42C54 42 46 44 40 52Z",
        "afro": "M40 56C36 34 52 24 64 24C76 24 92 34 88 56C86 44 78 40 64 40C50 40 42 44 40 56Z",
        "curly": "M40 56C36 34 52 24 64 24C76 24 92 34 88 56C86 44 78 40 64 40C50 40 42 44 40 56Z",
        "bun": "M39 56C34 34 50 24 64 24C80 24 94 34 89 56C87 47 83 41 76 38C68 42 54 42 48 38C43 41 41 49 39 56Z",
        "ponytail": "M40 54C38 34 50 26 64 26C78 26 90 34 88 54C84 44 76 38 64 36C52 38 44 44 40 54Z",
        "spiky": "M40 54L38 36L48 40L52 26L60 36L66 22L72 36L80 28L82 40L90 34L88 54C84 44 76 40 64 40C52 40 44 44 40 54Z",
    }
    if style in caps:
        return f'<path d="{caps[style]}" fill="{c}"/>'
    return ""


def avatar_svg(a):
    skin, shadow = SKIN[a["skin"]]
    hair = HAIR[a.get("hair", "black")]
    cloth = CLOTH[a["cloth"] % len(CLOTH)]
    bg = BG[a["bg"] % len(BG)]
    hijab = a.get("style") == "hijab"
    hijab_color = CLOTH[(a["cloth"] + 3) % len(CLOTH)]
    parts = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" width="128" height="128">',
             f'<defs><clipPath id="c"><circle cx="64" cy="64" r="64"/></clipPath></defs>',
             f'<g clip-path="url(#c)"><rect width="128" height="128" fill="{bg}"/>']
    if hijab:
        parts.append(f'<path d="M30 62C26 104 40 124 64 124C88 124 102 104 98 62C98 22 30 22 30 62Z" fill="{hijab_color}"/>')
    else:
        parts.append(hair_back(a.get("style", "short"), hair))
    # shoulders and neck
    parts.append(f'<path d="M12 128C12 104 38 94 64 94C90 94 116 104 116 128Z" fill="{cloth}"/>')
    parts.append(f'<rect x="55" y="74" width="18" height="24" rx="7" fill="{shadow}"/>')
    neck = a.get("neck", "crew")
    if neck == "vneck":
        parts.append(f'<path d="M52 94L64 110L76 94Z" fill="{skin}"/>')
    elif neck == "collar":
        parts.append(f'<path d="M50 94L64 108L78 94L72 92L64 100L56 92Z" fill="#FFFFFF"/>')
    else:
        parts.append(f'<path d="M53 94Q64 104 75 94Z" fill="{skin}"/>')
    # ears and head
    if not hijab:
        parts.append(f'<circle cx="41" cy="60" r="5.5" fill="{skin}"/><circle cx="87" cy="60" r="5.5" fill="{skin}"/>')
    parts.append(f'<ellipse cx="64" cy="56" rx="23" ry="26" fill="{skin}"/>')
    # face
    parts.append(f'<circle cx="46" cy="66" r="4.5" fill="#FF7A90" opacity=".28"/><circle cx="82" cy="66" r="4.5" fill="#FF7A90" opacity=".28"/>')
    parts.append(f'<circle cx="54" cy="57" r="2.8" fill="{INK}"/><circle cx="74" cy="57" r="2.8" fill="{INK}"/>')
    brow = "#2A2230" if a.get("hair", "black") in ("blonde", "gray", "white") else HAIR[a.get("hair", "black")]
    parts.append(f'<path d="M48 49Q54 45.5 59 49M69 49Q74 45.5 80 49" stroke="{brow}" stroke-width="2.4" fill="none" stroke-linecap="round"/>')
    parts.append(f'<path d="M64 59Q61 66 64.5 67" stroke="{shadow}" stroke-width="2" fill="none" stroke-linecap="round"/>')
    mouth = a.get("mouth", "smile")
    if mouth == "grin":
        parts.append('<path d="M54 69Q64 83 74 69Z" fill="#7A2E3A"/><path d="M56 69.5Q64 75 72 69.5Z" fill="#FFFFFF"/>')
    else:
        parts.append('<path d="M55 70Q64 78 73 70" stroke="#8B3A3A" stroke-width="2.5" fill="none" stroke-linecap="round"/>')
    # facial hair
    beard = a.get("beard")
    if beard == "beard":
        parts.append(f'<path d="M41 60C40 88 56 94 64 94C72 94 88 88 87 60C84 71 78 75 64 75C50 75 44 71 41 60Z" fill="{hair}"/>'
                     '<path d="M54 71Q64 84 74 71Z" fill="#7A2E3A"/><path d="M56 71.5Q64 77 72 71.5Z" fill="#FFFFFF"/>')
    elif beard == "stubble":
        parts.append(f'<path d="M42 62C42 84 56 90 64 90C72 90 86 84 86 62C84 72 76 78 64 78C52 78 44 72 42 62Z" fill="{hair}" opacity=".28"/>')
    elif beard == "mustache":
        parts.append(f'<path d="M51 66C57 61 64 65.5 64 65.5C64 65.5 71 61 77 66C73 71 66 68 64 68C62 68 55 71 51 66Z" fill="{hair}"/>')
    # front hair / hijab frame
    if hijab:
        parts.append(f'<path d="M37 58C37 36 50 27 64 27C78 27 91 36 91 58C85 43 75 39 64 39C53 39 43 43 37 58Z" fill="{hijab_color}"/>')
    else:
        parts.append(hair_front(a.get("style", "short"), hair))
    # glasses
    g = a.get("glasses")
    if g == "round":
        parts.append(f'<g fill="#FFFFFF" fill-opacity=".18" stroke="{INK}" stroke-width="2"><circle cx="54" cy="57" r="8.5"/><circle cx="74" cy="57" r="8.5"/></g>'
                     f'<path d="M62.5 56.5Q64 55 65.5 56.5" stroke="{INK}" stroke-width="2" fill="none"/>')
    elif g == "square":
        parts.append(f'<g fill="#FFFFFF" fill-opacity=".18" stroke="{INK}" stroke-width="2"><rect x="45" y="50.5" width="17" height="12.5" rx="3.5"/><rect x="66" y="50.5" width="17" height="12.5" rx="3.5"/></g>'
                     f'<path d="M62 55.5L66 55.5" stroke="{INK}" stroke-width="2"/>')
    parts.append("</g></svg>")
    return "".join(parts)


# key, label, parameters. Chosen for variety of skin tone, hair, age and style.
AVATARS = [
    ("01", "Short brown hair, glasses", dict(skin="fair", style="short", hair="brown", glasses="round", cloth=0, bg=0, neck="collar")),
    ("02", "Long dark hair", dict(skin="tan", style="long", hair="black", cloth=3, bg=1, neck="vneck", mouth="grin")),
    ("03", "Beard and glasses", dict(skin="brown", style="short", hair="black", beard="beard", glasses="square", cloth=1, bg=2, neck="collar")),
    ("04", "Blonde bob", dict(skin="light", style="bob", hair="blonde", cloth=6, bg=3, neck="crew")),
    ("05", "Curly hair", dict(skin="deep", style="afro", hair="black", cloth=2, bg=4, neck="vneck", mouth="grin")),
    ("06", "Bald with beard", dict(skin="tan", style="bald", hair="black", beard="beard", cloth=7, bg=5, neck="crew")),
    ("07", "Hijab, teal", dict(skin="fair", style="hijab", cloth=1, bg=6, neck="crew")),
    ("08", "Side part, stubble", dict(skin="light", style="sidepart", hair="auburn", beard="stubble", cloth=4, bg=7, neck="collar")),
    ("09", "Hair bun", dict(skin="brown", style="bun", hair="black", cloth=5, bg=8, neck="vneck")),
    ("10", "Spiky blue hair", dict(skin="fair", style="spiky", hair="blue", cloth=9, bg=9, neck="crew", mouth="grin")),
    ("11", "Gray hair, mustache", dict(skin="light", style="short", hair="gray", beard="mustache", glasses="round", cloth=8, bg=0, neck="collar")),
    ("12", "Ponytail", dict(skin="tan", style="ponytail", hair="chestnut", cloth=2, bg=1, neck="crew", mouth="grin")),
    ("13", "Buzz cut, glasses", dict(skin="dark", style="buzz", hair="black", glasses="square", cloth=3, bg=2, neck="crew")),
    ("14", "Long ginger hair", dict(skin="light", style="long", hair="ginger", cloth=1, bg=3, neck="vneck", mouth="grin")),
    ("15", "Curly with glasses", dict(skin="brown", style="curly", hair="brown", glasses="round", cloth=6, bg=4, neck="crew")),
    ("16", "Short black hair", dict(skin="tan", style="short", hair="black", cloth=7, bg=5, neck="collar", mouth="grin")),
    ("17", "Hijab, purple", dict(skin="tan", style="hijab", cloth=3, bg=7, neck="vneck", mouth="grin")),
    ("18", "Pink bob", dict(skin="fair", style="bob", hair="pink", cloth=0, bg=8, neck="crew")),
    ("19", "White hair, beard", dict(skin="light", style="sidepart", hair="white", beard="beard", cloth=4, bg=9, neck="collar")),
    ("20", "Teal long hair", dict(skin="deep", style="long", hair="teal", cloth=9, bg=0, neck="vneck", mouth="grin")),
    ("21", "Side part, glasses", dict(skin="brown", style="sidepart", hair="black", glasses="round", cloth=5, bg=1, neck="collar")),
    ("22", "Blonde short", dict(skin="light", style="short", hair="blonde", beard="stubble", cloth=2, bg=2, neck="crew", mouth="grin")),
    ("23", "Afro, glasses", dict(skin="dark", style="afro", hair="black", glasses="square", cloth=1, bg=3, neck="crew")),
    ("24", "Bun, glasses", dict(skin="light", style="bun", hair="auburn", glasses="round", cloth=6, bg=4, neck="vneck", mouth="grin")),
    ("25", "Bald", dict(skin="brown", style="bald", hair="black", cloth=8, bg=5, neck="collar", mouth="grin")),
    ("26", "Chestnut ponytail", dict(skin="fair", style="ponytail", hair="chestnut", glasses="square", cloth=3, bg=6, neck="crew")),
    ("27", "Stubble, short hair", dict(skin="dark", style="short", hair="black", beard="stubble", cloth=4, bg=7, neck="vneck")),
    ("28", "Curly ginger", dict(skin="light", style="curly", hair="ginger", cloth=7, bg=8, neck="crew", mouth="grin")),
    ("29", "Mustache, side part", dict(skin="tan", style="sidepart", hair="brown", beard="mustache", cloth=0, bg=9, neck="collar")),
    ("30", "Hijab, rose", dict(skin="brown", style="hijab", cloth=5, bg=0, neck="crew")),
    ("31", "Buzz, beard", dict(skin="fair", style="buzz", hair="brown", beard="beard", cloth=9, bg=1, neck="collar")),
    ("32", "Long gray hair", dict(skin="light", style="long", hair="gray", glasses="round", cloth=2, bg=2, neck="vneck")),
]

if __name__ == "__main__":
    presets = []
    for key, label, params in AVATARS:
        name = f"avatar-{key}"
        (OUT / "svg" / f"{name}.svg").write_text(avatar_svg(params))
        presets.append({"key": name, "label": label})
    (OUT / "presets.json").write_text(json.dumps(presets, indent=2) + "\n")
    print(f"wrote {len(presets)} avatars")
