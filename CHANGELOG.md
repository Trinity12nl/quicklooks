# Changelog

## Unreleased

- **NEW** Python (`.py`, `.pyw`, `.pyi`) and SQL (`.sql`) files are coloured
  by the dotfile previewer: comments, strings, numbers, keywords, and Python
  `"""` docstrings as a block. `.sql` is also claimed under Sequel Ace's type.

- **FIX** An XML `.config` (`web.config`, `app.config`) got INI colours; the
  INI previewer now hands a file that starts with `<` to the XML renderer.

- **FIX** `.ini`, `.toml`, `.cfg` and `.config` got no preview on Macs where
  nothing declares `com.microsoft.ini` and `public.toml` (such as macOS
  26.6.2). The host app now imports both types.

- **NEW** Markdown previewer (`.md`, `.markdown`): rendered headings, emphasis,
  lists, task lists, quotes, tables and links, with code in green monospace.
  YAML front matter is shown as a block at the top. Works in light and dark mode.
  Fenced code blocks are coloured per language tag; inline code has rounded
  corners. A Preview | Source switch shows the coloured, line-numbered source.
- **FIX** `build-quicklooks.sh` failed when the checkout path contained a space:
  source paths are now passed to `swiftc` as an array.
