# Bar Dial

Scroll the Omarchy bar to resize your shell, GTK, and terminal text — on the
fly. Click for a slider and a one-click reset.

## What it does

- Scroll up/down on the **"Aa"** indicator in your bar to step text size by
  1px at a time.
- Click it to open a small panel with a slider (8–32px) and a
  **Reset to default** button.
- The displayed size is read live from the Omarchy shell itself, so it always
  matches reality. Changes are applied through the official
  `omarchy display text size` command, which scales GTK apps and terminal
  fonts along with the shell — not just the bar.

## Requirements

[Omarchy](https://omarchy.org/) (Quattro shell) with the `omarchy` CLI on
`PATH`. No other dependencies — this plugin only shells out to a command
already installed on the system.

## Install

```bash
omarchy plugin add https://github.com/ukkit/omarchy-bar-dial --enable
```

Or manually:

```bash
git clone https://github.com/ukkit/omarchy-bar-dial ~/.config/omarchy/plugins/io.github.ukkit.bar-dial
omarchy plugin enable io.github.ukkit.bar-dial
```

## Remove

```bash
omarchy plugin remove io.github.ukkit.bar-dial
```

## License

MIT — see [LICENSE](LICENSE). No third-party code is bundled.
