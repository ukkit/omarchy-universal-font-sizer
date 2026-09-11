# Universal Font Sizer

Scroll the Omarchy bar to resize your shell, GTK, and terminal text — on the
fly. Click for a slider, a live preview, and a one-click reset.

## What it does

- Scroll up/down on the **🌐** indicator in your bar to step the base font
  size by 1px at a time. Since every other size in the shell (titles,
  captions, icons, bar height) scales off that one base value, this one
  gesture resizes everything at once — hence "universal."
- Click it to open a small panel with a slider (8–32px), +/− steppers, a
  live preview of a few representative sizes, and a **Reset to default**
  button.
- The displayed size is read live from the Omarchy shell itself, so it always
  matches reality. Changes are applied through the official
  `omarchy display text size` command, which scales GTK apps and terminal
  fonts along with the shell — not just the bar.

## Requirements

[Omarchy](https://omarchy.org/) (Quattro shell) with the `omarchy` CLI on
`PATH`. No other dependencies — this plugin only shells out to a command
already installed on the system.

## Privilege boundary

Runs with your normal user permissions, same as the shell itself — no sudo,
no elevated capabilities. The only command it ever runs is
`omarchy display text size [<value>|reset]`. No network access, no files
read or written beyond what that command itself does, no data collected or
sent anywhere.

## Install

```bash
omarchy plugin add https://github.com/ukkit/omarchy-universal-font-sizer --enable
```

Or manually:

```bash
git clone https://github.com/ukkit/omarchy-universal-font-sizer ~/.config/omarchy/plugins/io.github.ukkit.universal-font-sizer
omarchy plugin enable io.github.ukkit.universal-font-sizer
```

## Remove

```bash
omarchy plugin remove io.github.ukkit.universal-font-sizer
```

## License

MIT — see [LICENSE](LICENSE). No third-party code is bundled.
