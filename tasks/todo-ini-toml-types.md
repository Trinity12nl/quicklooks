# Fix: .ini, .toml, .cfg and .config get no preview

## Problem

`INIPreviewer` claims `com.microsoft.ini` and `public.toml`, and the README
says macOS declares both. On Inge's Mac (macOS 26.6.2) nothing declares them:

- `UTType("public.toml")?.isDeclared == false`, same for `com.microsoft.ini`
- `.ini`, `.toml`, `.cfg`, `.config` resolve to `dyn.*` types
- `lsregister -dump`: the only mention of either type is INIPreviewer's own
  `QLSupportedContentTypes`

Proven with the original repo (y-a-v-a/quicklooks `main`, 74e636e) built and
installed: `qlmanage -p` starts no previewer for `sample.ini` or
`sample.toml`, while `sample.yaml` starts `YAMLPreviewer`. Not caused by our
changes.

## Fix

Import both types in the host app's `UTImportedTypeDeclarations`, conforming
to `public.plain-text` like the other text types there:

- `com.microsoft.ini`: `ini`
- `public.toml`: `toml`, `cfg`, `config` (the README's mapping)

An imported declaration is ignored where something declares the type (the
README explains this), so Macs that already have the types are unaffected;
on Macs without them it fills the gap.

## Todo

- [x] Branch `fix/declare-ini-toml` from `main`
- [x] Two imported declarations in `build-quicklooks.sh`, update its comment
- [x] README: note that the two types are not declared on every Mac
- [x] CHANGELOG entry
- [x] Build; verify `.ini`, `.toml`, `.cfg`, `.config` resolve to the
      imported types and `qlmanage -p` starts `INIPreviewer`
- [x] Inge tests manually (ini, toml)
- [x] `samples/sample.cfg` + line in `samples/README.md` (Inge asked: no
      .cfg/.config samples existed). No `sample.config`: XML `.config` files
      (web.config) get INI colours, a separate follow-up if wanted. Known
      limitation of the INI lexer: an indented continuation line containing
      `=` (`    requests>=2.31`) is read as key = value.
- [ ] Commit, PR on the fork; later a separate small PR for y-a-v-a

## Review

- `build-quicklooks.sh`: `com.microsoft.ini` (`ini`) and `public.toml`
  (`toml`, `cfg`, `config`, MIME `application/toml`) added to the host app's
  `UTImportedTypeDeclarations`, conforming to `public.plain-text`; comment
  above the plist explains why.
- README: paragraph under "Why this is needed at all"; CHANGELOG entry.
- Verified after install: all four extensions resolve to the imported types,
  and `qlmanage -p` starts `INIPreviewer` for `sample.ini`, `sample.toml`,
  `app.cfg` and `app.config`; `sample.yaml` -> `YAMLPreviewer` and
  `sample.md` -> `MarkdownPreviewer` unchanged.
