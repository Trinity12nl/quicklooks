# Previews for Python (.py) and SQL (.sql)

## Findings (macOS 26.6.2, Inge's Mac)

| | `.py` | `.sql` |
| --- | --- | --- |
| Type | `public.python-script` (declared by macOS) | `com.sequel-ace.sequel-ace.sql` (declared by the Sequel Ace app) |
| Preview now | macOS plain text, no colour | macOS plain text, no colour |
| Mac without that app | same | probably `dyn.*`: no preview at all |

`.pyw` and `.pyi` resolve to `dyn.*`.

The project already colours Go, Rust, Lua and friends through
`DotfilePreviewer`: `DotfileRenderer.byExtension` maps an extension to a
`PlainTextRenderer.Syntax` (comments, strings, keywords), and the README
documents this as the way to add a language. Python and SQL fit that.

## Design

- `PlainTextRenderer.Syntax`: two new presets next to `.shell`, `.hash` etc.
  - `.python`: `#` comments, `"`/`'` strings, Python keywords, and `"""`
    docstrings as a block (so multi-line docstrings colour as one unit)
  - `.sql`: `--` and `/* */` comments, `'`/`"` strings, SQL keywords in upper
    and lower case
- `DotfileRenderer.byExtension`: `py`, `pyw`, `pyi` -> `.python`; `sql` -> `.sql`
- `build-quicklooks.sh`:
  - `DotfilePreviewer` also claims `public.python-script` and
    `com.sequel-ace.sequel-ace.sql` (takes over the plain built-in preview,
    like `JSONPreviewer` does for `.json`)
  - `pyw pyi sql` added to `SOURCE_EXTS`, so they are declared on Macs where
    nothing else declares them
- `MarkdownCode` (fork only): use the shared `.python` / `.sql` presets
  instead of its own copies, so fenced code and files colour the same
- Samples: new `samples/sample.py` with the awkward cases (docstrings, `#` in
  strings, f-strings, decorators); `samples/sample.sql` already exists and
  becomes the SQL sample as well
- README table + text, `samples/README.md`, CHANGELOG

## Known limits (shallow scanner, same as for the other languages)

- `'''` docstrings: only one block style per language, `"""` is by far the
  most common
- SQL keywords in mixed case (`Select`) are not coloured
- Other SQL apps' own `.sql` types (TablePlus, DataGrip, ...) are not
  claimed; on such a Mac `.sql` keeps that app's preview

## Todo

- [x] Branch `feature/python-sql-preview` from `main`
- [x] `.python` and `.sql` presets in `PlainTextRenderer.Syntax`
- [x] Routes in `DotfileRenderer.byExtension`
- [x] UTIs + `SOURCE_EXTS` in `build-quicklooks.sh`
- [x] `MarkdownCode` uses the shared presets
- [x] `samples/sample.py`, samples README, README, CHANGELOG
- [ ] Verify (render + `qlmanage -p` process check), Inge tests
- [ ] Commit, PR on fork; separate clean PR for y-a-v-a

## Review

- `PlainTextRenderer.Syntax`: new presets `.python` (`#`, `"""` docstring
  block, keywords, string prefixes) and `.sql` (`--`, `/* */`, keywords in
  both cases). New `stringPrefixes` option, empty by default, so `f"…"`,
  `r"…"`, `rb"…"` open a string in Python; other languages unchanged.
- `DotfileRenderer.byExtension`: `py`/`pyw`/`pyi` -> `.python`, `sql` -> `.sql`.
- `build-quicklooks.sh`: DotfilePreviewer also claims `public.python-script`
  and `com.sequel-ace.sequel-ace.sql`; `pyw pyi sql` in `SOURCE_EXTS`.
- `MarkdownCode` uses the shared presets (fork only; upstream lacks it until
  the Markdown PR is merged).
- `samples/sample.py`; `sample.sql` documented as SQL sample too; README,
  samples README, CHANGELOG.
- Found while verifying: f-strings were not coloured (a letter before the
  quote blocks a string); fixed with `stringPrefixes`.
- Verified: renders of sample.py, sample.sql and a prefix test file; after
  install `qlmanage -p` starts DotfilePreviewer for .py/.pyw/.pyi/.sql, and
  .md/.config/.zshrc are unchanged; Markdown's Python block still coloured.
