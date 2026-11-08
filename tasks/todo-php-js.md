# Previews for PHP and JavaScript

Same route as Python/SQL (PR #6). TypeScript is left out for now: `.ts`
resolves to `public.mpeg-2-transport-stream` (video) and `.mts` to AVCHD
video, so claiming them needs a test with real video files first.

## Findings (macOS 26.6.2)

| Extension | Type | Now |
| --- | --- | --- |
| `.php`, `.phtml` | `public.php-script` (macOS) | plain built-in preview |
| `.js`, `.mjs` | `com.netscape.javascript-source` (macOS) | plain built-in preview |
| `.jsx`, `.cjs` | `nl.vincentbruijn.source-text` (this project) | C-like colours, no keywords |

## Design

- `PlainTextRenderer.Syntax`:
  - `.php`: `//`, `#` and `/* */` comments, `"`/`'`/`` ` `` strings,
    `$variables` (the shell variable rule), PHP keywords
  - `.javascript`: C-like comments and strings, JS keywords (the list
    `MarkdownCode` already uses, which also covers TypeScript words for
    fenced `ts` blocks)
- `DotfileRenderer.byExtension`: `php`, `phtml` -> `.php`; `js`, `mjs`,
  `cjs`, `jsx` -> `.javascript`
- `build-quicklooks.sh`: DotfilePreviewer also claims `public.php-script`
  and `com.netscape.javascript-source`
- `MarkdownCode` uses the shared presets for js/ts/php fences
- `samples/sample.php`, `samples/sample.js` with awkward cases; samples
  README, README table, CHANGELOG

## Known limits (shallow scanner)

- A JS regex literal containing `//` (`/\/\//`) is read as a comment
- PHP mixed with HTML: the HTML parts are not coloured as HTML
- `#[Attribute]` (PHP 8) at line start colours as a comment

## Todo

- [x] Branch `feature/php-js-preview` from `main`
- [x] `.php` and `.javascript` presets
- [x] Routes in `DotfileRenderer.byExtension`
- [x] UTIs in `build-quicklooks.sh`
- [x] `MarkdownCode` uses the shared presets
- [x] Samples + docs
- [ ] Verify (render + `qlmanage -p`), Inge tests
- [ ] Commit, PR on fork; maker PR later together with Python/SQL

## Addendum: minified JavaScript (raised by a side agent, confirmed by measuring)

Measured (render = scanner, layout = text view): `axe.min.js` 652 KB:
0.13 s + 0.34 s, fine. A 3 MB bundle on one line: 0.98 s + 13.6 s. The cost
is laying out one giant line.

Same method as the XML previewer: if the longest line is over 5,000
characters, add line breaks first, then the usual 5,000-line cap applies.
For JavaScript: break after `;` (not inside `for (…)`), `{` and `}`, indent by
brace depth, and copy strings, template literals, comments and regex
literals untouched. Header says "minified, line breaks added". New file
`Sources/Formats/Dotfile/CodeReflow.swift`; only syntaxes that opt in
(`.javascript`) are reflowed.

- [x] `CodeReflow.swift` + opt-in flag on `Syntax`, hook in `PlainTextRenderer`
- [x] Measure again: 3 MB bundle and axe.min.js; sample.js unchanged

## Review

- `PlainTextRenderer.Syntax`: `.javascript` (C-like + JS/TS keywords) and
  `.php` (`//`, `#`, `/* */`, `$variables`, PHP keywords).
- `DotfileRenderer.byExtension`: `js mjs cjs jsx` -> `.javascript` (`jsx`,
  `cjs` moved out of the plain C-like list), `php phtml` -> `.php`.
- `build-quicklooks.sh`: DotfilePreviewer also claims `public.php-script`
  and `com.netscape.javascript-source`.
- `MarkdownCode`: js/ts and php fences use the shared presets (php used to
  get the C keyword list).
- `samples/sample.php`, `samples/sample.js`; README rows, samples README,
  CHANGELOG.
- Verified: renders of both samples; after install `qlmanage -p` starts
  DotfilePreviewer for .php/.phtml/.js/.mjs/.cjs/.jsx; .py and .md
  unchanged; Markdown harness renders all modes.
- Minified JS: `CodeReflow.swift` (191 lines) breaks after `;`/`{`/`}` with
  indentation, leaving strings, templates, comments and regexes untouched;
  parens are counted per brace level so `(function(){…})()` bundles still
  break. Opt-in via `Syntax.reflowsMinified` (only `.javascript`). Header
  says "minified, line breaks added". 3 MB one-line bundle: 14.6 s -> 0.4 s;
  axe.min.js 0.5 s -> 0.7 s (now coloured per line); sample.js unchanged.
- Language presets moved from `PlainTextRenderer.swift` (was 311 lines) to
  `Languages.swift`; PlainTextRenderer back to ~265 lines and closer to the
  original.
