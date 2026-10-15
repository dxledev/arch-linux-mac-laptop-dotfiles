#!/usr/bin/env python3
"""Apply the legion dotfiles' terminal algorithm, then enforce readability."""

import argparse
import os
from pathlib import Path
import sys
import tempfile
import tomllib

sys.dont_write_bytecode = True
import reference_contrast_palette as reference


NAMES = ("black", "red", "green", "yellow", "blue", "magenta", "cyan", "white")
TEXT_CONTRAST = 4.5
ANSI_CONTRAST = 3.0
ROLE_DISTANCE = 0.06

# Same mappings as bin-files/bin/noctalia-theme-sync:convert_palette.
MAPPING = {
    "base": ("background", "surface"),
    "text": ("on_background", "on_surface"),
    "subtext1": ("on_surface_variant", "on_surface"),
    "subtext0": ("outline", "on_surface_variant"),
    "primary": ("primary", "source_color"),
    "red": ("terminal_normal_red", "error"),
    "green": ("terminal_normal_green", "primary"),
    "yellow": ("terminal_normal_yellow", "tertiary"),
    "peach": ("terminal_bright_yellow", "tertiary"),
    "pink": ("terminal_bright_magenta", "secondary"),
    "mauve": ("tertiary", "primary"),
    "blue": ("terminal_normal_blue", "primary"),
    "teal": ("terminal_bright_cyan", "secondary"),
    "sky": ("terminal_normal_cyan", "secondary"),
}
TERMINAL_FALLBACKS = (
    "surface_variant", "error", "primary", "tertiary",
    "primary", "secondary", "secondary", "on_surface",
    "outline", "error", "primary", "tertiary",
    "primary", "secondary", "secondary", "on_surface",
)


def normalize(source):
    mode = source["mode"]
    if mode not in ("dark", "light"):
        raise ValueError("palette mode must be dark or light")
    native = {key: reference.parse_colour(value) for key, value in source["colors"].items()}
    if not any(key in native for key in ("background", "surface")) or not any(
        key in native for key in ("on_background", "on_surface")
    ):
        raise ValueError("palette must include background and foreground colors")

    def pick(names):
        return next((native[name] for name in names if name in native), "000000")

    colours = {name: pick(keys) for name, keys in MAPPING.items()}
    terminal = [
        pick((f"terminal_{section}_{name}", TERMINAL_FALLBACKS[index]))
        for index, (section, name) in enumerate(
            (section, name) for section in ("normal", "bright") for name in NAMES
        )
    ]
    candidates = sorted(set(native.values()) | set(colours.values()) | set(terminal))
    # Degenerate custom palettes still need two distinct ANSI black candidates.
    if len(candidates) < 2:
        candidates = sorted(set(candidates) | {"000000", "ffffff"})
    return {"mode": mode, **colours}, candidates, terminal


def readable(original, background, candidates, assigned, target):
    if reference.contrast_ratio(original, background) >= target:
        return original
    pool = [colour for colour in candidates if reference.contrast_ratio(colour, background) >= target]
    # Black or white always reaches 4.5:1 against an opaque RGB background.
    if not pool:
        pool = [colour for colour in ("000000", "ffffff")
                if reference.contrast_ratio(colour, background) >= target]
    return reference.choose_replacement(
        original, background, pool, assigned, target, ROLE_DISTANCE, contrast_priority=True
    )


def generate(source):
    palette, candidates, terminal = normalize(source)
    plan = reference.render_plan(
        palette, candidates, terminal, TEXT_CONTRAST, ANSI_CONTRAST, ROLE_DISTANCE
    )
    background = palette["base"]
    foreground = readable(plan["text"], background, candidates, [], TEXT_CONTRAST)
    corrected = list(plan["terminal"])
    fixes = []
    for index, colour in enumerate(corrected):
        if index in (0, 8):
            continue  # Preserve the reference's reserved ANSI black slots.
        if reference.contrast_ratio(colour, background) >= ANSI_CONTRAST:
            continue
        # Reuse the slot's authored hue if it is readable. Separation must not
        # force an already-readable bright color into a darker replacement.
        replacement = readable(
            terminal[index], background, candidates,
            corrected[:index] + corrected[index + 1:], ANSI_CONTRAST
        )
        if replacement != colour:
            fixes.append(f"ANSI {index} {NAMES[index % 8]}: #{colour} -> #{replacement}")
            corrected[index] = replacement

    colors = {
        "primary": {"background": f"#{background}", "foreground": f"#{foreground}"},
        "normal": dict(zip(NAMES, (f"#{colour}" for colour in corrected[:8]))),
        "bright": dict(zip(NAMES, (f"#{colour}" for colour in corrected[8:]))),
    }
    # Avoid Alacritty's automatic dimming lowering the validated contrast.
    colors["dim"] = dict(colors["normal"])
    validate(colors)
    lines = [
        "# Generated with the legion dotfiles' algorithm and readable fallbacks.",
        "# ANSI black slots retain the reference's reserved dark colors.",
    ]
    for section, values in colors.items():
        lines.extend(("", f"[colors.{section}]"))
        lines.extend(f'{key} = "{value}"' for key, value in values.items())
    rendered = "\n".join(lines) + "\n"
    # Validate the serialized RGB values before publishing.
    validate(tomllib.loads(rendered)["colors"])

    report = [
        "Alacritty contrast validation: PASS",
        f"Text: {reference.contrast_ratio(foreground, background):.3f}:1 (minimum 4.5:1)",
        "ANSI black slots: reserved dark colors, excluded from the 3:1 target",
        *[
            f"ANSI {index} {NAMES[index % 8]}: "
            f"{reference.contrast_ratio(colour, background):.3f}:1 (minimum 3:1)"
            for index, colour in enumerate(corrected) if index not in (0, 8)
        ],
        "Readable fallbacks: " + (", ".join(fixes) if fixes else "none"),
        "Reference report (before readable fallbacks):",
        *plan["report"],
    ]
    return rendered, "\n".join(report) + "\n"


def validate(colors):
    background = colors["primary"]["background"]
    if reference.contrast_ratio(colors["primary"]["foreground"], background) < TEXT_CONTRAST:
        raise ValueError("primary foreground does not meet 4.5:1 contrast")
    for section in ("normal", "bright", "dim"):
        for name in NAMES:
            colour = colors[section][name]
            reference.parse_colour(colour)
            if name != "black" and reference.contrast_ratio(colour, background) < ANSI_CONTRAST:
                raise ValueError(f"{section}.{name} does not meet 3:1 contrast")


def atomic_write(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists() and path.read_text() == content:
        return
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, prefix=f".{path.name}.",
                                         delete=False, encoding="utf-8") as output:
            temporary = Path(output.name)
            output.write(content)
            output.flush()
            os.fsync(output.fileno())
        temporary.replace(path)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


def main():
    config_home = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
    state_home = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state"))
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--palette", type=Path, default=state_home / "noctalia/alacritty/palette.toml")
    parser.add_argument("--output", type=Path, default=config_home / "alacritty/themes/noctalia-contrast.toml")
    parser.add_argument("--report", type=Path, default=state_home / "noctalia/alacritty/contrast-report.txt")
    args = parser.parse_args()
    try:
        rendered, report = generate(tomllib.loads(args.palette.read_text()))
        atomic_write(args.output, rendered)
        atomic_write(args.report, report)
    except (OSError, ValueError, KeyError, TypeError) as error:
        print(f"alacritty-contrast: {error}", file=sys.stderr)
        return 1
    print(report.splitlines()[0])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
