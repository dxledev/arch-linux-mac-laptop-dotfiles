Alacritty follows Noctalia through a user template declared in
`.config/noctalia/alacritty.toml`. The template exports all resolved color
tokens to `~/.local/state/noctalia/alacritty/palette.toml`; its synchronous
post-hook generates `~/.config/alacritty/themes/noctalia-contrast.toml`.

`scripts/reference_contrast_palette.py` is an unchanged copy of
`quickshell/.config/quickshell/caelestia/integration/contrast-palette.py` from
`~/builds/arch-linux-legion-dotfiles`, commit
`2b437756bb5fb169ee8b7c2f02effd31eaf211a1`. The wrapper uses the same native
color mappings as that repository's `bin-files/bin/noctalia-theme-sync` and
the same targets: text 4.5:1, ANSI colors 3:1, OKLab separation 0.06.

The reference sometimes sacrifices readability when it runs out of distinct
source colors. The wrapper preserves passing output and repairs only failing
foregrounds. It first reuses the slot's original color if readable, otherwise
chooses a readable source color. If no source color passes, it uses black or
white. Readability takes priority over color separation, so colors can repeat.
The two reserved ANSI black slots retain the reference's dark treatment and
are exempt from the 3:1 target. Explicit dim colors match normal colors so
Alacritty cannot automatically dim them below the validated contrast.

The generated, serialized RGB values are validated before atomic publication.
Malformed input leaves the previous theme intact. Unchanged themes are not
rewritten. The latest measurements and the reference's original report are in
`~/.local/state/noctalia/alacritty/contrast-report.txt`.

Keep the built-in Alacritty template enabled and import `noctalia.toml` first,
then `noctalia-contrast.toml`. This preserves Noctalia's cursor, search, hint,
and selection settings while the validated palette overrides terminal colors.
It also prevents the built-in apply script from appending its import after the
contrast override. No system templates or reference repository files are edited.

Run checks with:

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s ~/.dotfiles/alacritty/tests -v
```

Noctalia's [user template documentation](https://docs.noctalia.dev/noctalia/theming/app-theming/)
and [hook reference](https://docs.noctalia.dev/noctalia/theming/templates/) describe
the automatic updates and synchronous hook ordering.
