# Fix: XML `.config` files get INI colours

## Problem

Since `.config` resolves to `public.toml` (PR #4), an XML `.config` such as
.NET's `web.config` / `app.config` reaches `INIPreviewer` and is coloured with
INI rules: tags and comments come out as red "values".

## Fix

`INIPreviewer`'s controller looks at the start of the file: if the first
non-whitespace character (after a UTF-8 or UTF-16 byte order mark) is `<`,
it renders with the existing `XMLRenderer` instead of `INIRenderer`. An INI
or TOML file never starts with `<`, so nothing else changes. Decided on
content rather than extension, like `JSONPreviewer` retrying as JSONL.

Only the INI previewer's controller changes; `DotfilePreviewer`, which also
uses `INIRenderer` for `.gitconfig` and friends, is untouched.

## Todo

- [x] Branch `fix/xml-config-in-ini-previewer` from `main`
- [x] Sniff + route in `INIPreviewViewController.swift`
- [x] Add the XML sources to `INIPreviewer` in `build-quicklooks.sh`
- [x] `samples/sample.config` (XML web.config) + line in `samples/README.md`
- [x] README: INI paragraph; CHANGELOG entry
- [ ] Verify: XML `.config` -> XML colours, `sample.ini`/`.toml`/`.cfg`
      unchanged; build, Inge tests
- [ ] Commit, PR on fork; separate PR for y-a-v-a

## Review

- `INIPreviewViewController`: `startsWithTag(_:)` reads the first 512 bytes,
  decodes UTF-16 when there is a UTF-16 BOM, skips a UTF-8 BOM and whitespace;
  `<` -> `XMLRenderer`, else `INIRenderer` as before.
- `build-quicklooks.sh`: INIPreviewer now also compiles ByteReader,
  XMLHighlighter and XMLRenderer.
- `samples/sample.config` (web.config) + `samples/README.md`; README INI
  paragraph; CHANGELOG.
- Verified through the controller's real `render(url:)`: sample.config,
  a UTF-16 config and a UTF-8-BOM config get the XML preview; sample.ini,
  sample.toml, sample.cfg render as before. After install, `qlmanage -p`
  starts INIPreviewer for .config/.ini/.toml/.cfg.
