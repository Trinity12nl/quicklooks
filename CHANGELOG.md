# Changelog

## Unreleased

- **NEW** Markdown previewer (`.md`, `.markdown`): rendered headings, emphasis,
  lists, task lists, quotes, tables and links, with code in green monospace.
  YAML front matter is shown as a block at the top. Works in light and dark mode.
  Fenced code blocks are coloured per language tag; inline code has rounded
  corners.
- **FIX** `build-quicklooks.sh` failed when the checkout path contained a space:
  source paths are now passed to `swiftc` as an array.
