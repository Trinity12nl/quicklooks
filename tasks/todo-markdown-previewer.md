# Markdown Quick Look previewer

## Goal

Press space on a `.md` / `.markdown` file in Finder and get a **rendered**
preview (headings, bold/italic, lists, code blocks, tables, quotes, links)
instead of the plain-text preview macOS shows by default.

## Findings

- `.md` resolves to `net.daringfireball.markdown` (declared by macOS, conforms
  to `public.plain-text`), so we can claim that UTI directly in
  `QLSupportedContentTypes`, like `JSONPreviewer` does for `public.json`. No
  new UTI declaration is needed in the host app's Info.plist.
- Foundation's `AttributedString(markdown:options: .full)` (macOS 12+, the
  project targets 13) parses full CommonMark + GFM tables and strikethrough
  into `presentationIntent` (block) and `inlinePresentationIntent` (inline)
  attributes. Verified with a test script. So no external dependency and no
  hand-written parser: we only map those intents to AppKit styling.
- Not handled by the parser: YAML front matter (`---` block at the top), task
  list checkboxes (`- [ ]` stays text), images (we show the alt text), raw
  HTML (shown as dimmed source).
- The existing `TextPreviewController` (scrolling `NSTextView`) can show any
  attributed string, so the extension is just a renderer + a 7-line view
  controller, the same shape as every other previewer.
- **Conflict on this Mac:** "Folder Quick Look" ships an enabled
  `Markdown Quick Look Extension` that also claims markdown. To test ours,
  that one has to be turned off in System Settings → Login Items & Extensions
  → Quick Look (or we check with `qlmanage -p`, which shows which one wins).

## Design

`Sources/Formats/Markdown/MarkdownRenderer.swift` (target < 300 lines):

1. Read the file (cap at e.g. 2 MB, header says so when truncated), UTF-8
   with Latin-1 fallback like the XML previewer.
2. Strip YAML front matter and show it dimmed in monospace at the top.
3. Parse with `AttributedString(markdown:, options: .init(interpretedSyntax: .full,
   failurePolicy: .returnPartiallyParsedIfPossible))`.
4. Walk the runs, grouping by block (`presentationIntent` identity), and
   produce an `NSAttributedString`:
   - headers 1-6: larger bold system font, spacing above
   - paragraphs: system font 13 pt, paragraph spacing
   - bold / italic / strikethrough / inline code (monospace + subtle background)
   - links: blue + underlined (`.link` attribute, clickable)
   - unordered / ordered lists: bullet or number, indented per nesting level;
     `[ ]` / `[x]` become ☐ / ☑
   - block quotes: indented, secondary colour
   - code blocks: monospace, background, language label dimmed
   - tables: `NSTextTable` cells with header row bold and column alignment
   - thematic break: a dimmed line
5. Header line via the shared `reportHeader` (name, size, line count) to match
   the other previewers.

`Sources/Formats/Markdown/MarkdownPreviewViewController.swift`: 7-line
subclass of `TextPreviewController`, same as YAML/Log/Font.

## Todo

- [x] Create branch `feature/markdown-previewer` from `main`
- [x] `MarkdownRenderer.swift` (parse + block/inline styling, front matter, tables)
- [x] `MarkdownPreviewViewController.swift`
- [x] Register `MarkdownPreviewer:markdown:net.daringfireball.markdown` in
      `EXTENSIONS` in `build-quicklooks.sh` and add it to the header comment
- [x] Add `samples/sample.md` covering all elements (front matter, nested
      lists, task list, table with alignment, code block, quote, HTML, image)
- [x] README: row in the table + short "Markdown" paragraph (incl. the
      conflict note about other markdown Quick Look apps)
- [x] Add a `CHANGELOG.md` (repo has none) with the entry for this feature
- [x] Build with `./build-quicklooks.sh`, verify with `pluginkit` and
      `qlmanage -p samples/sample.md`, screenshot as evidence
- [ ] You test manually in Finder
- [ ] Commit, `gh pr create` against **your fork** (`Trinity12nl/quicklooks`),
      merge after your approval

## Decision (Inge, 2026-11-08)

Rendered, with coloured code, styled after Inge's reference screenshot:
- H1/H2 large and bold, with a dotted rule underneath
- inline code: green monospace on a light-green background
- code blocks: green monospace in a rounded light-green box with padding
- light and dark mode both get matching colours (dynamic NSColors)

## Review

**New files**
- `Sources/Formats/Markdown/MarkdownRenderer.swift` (273 lines): reads up to
  2 MB, splits off front matter, parses with Foundation's
  `AttributedString(markdown:)` and writes each block (heading, paragraph,
  list item, quote, code block, table cell, rule) as AppKit attributes.
- `Sources/Formats/Markdown/MarkdownStyle.swift` (100 lines): fonts, dynamic
  light/dark colours, and `MarkdownBlock`, an `NSTextBlock` subclass that draws
  the rounded code fill, the dotted heading rule and the quote bar.
- `Sources/Formats/Markdown/MarkdownPreviewViewController.swift`: the usual
  subclass of `TextPreviewController`.
- `samples/sample.md`, `CHANGELOG.md`.

**Changed**
- `build-quicklooks.sh`: `MarkdownPreviewer` added to `EXTENSIONS`, claiming
  `net.daringfireball.markdown` (declared by macOS, so no host-app UTI needed).
- `build-quicklooks.sh` **bug fix**: the script broke on a checkout path with a
  space (`Claude Projecten`), because the source list was word-split. It is now
  a bash array. Pre-existing bug, found while building.
- `README.md`: table row, layout listing, and a Markdown paragraph.

**Issues found and fixed along the way**
- A bare `NSTextBlock` has zero width, so text in it stacked one character per
  line. Fixed by giving `MarkdownBlock` a 100% width.
- The parser drops empty table cells; `NSTextTable` needs all of them, so the
  writer fills the gaps per row.
- Block HTML kept its own newline (an extra empty line); trimmed.
- Inline code padding used a breakable thin space, which left an empty green
  box at a line end when wrapping; now a narrow no-break space.

**Verification**
- Offscreen render of `samples/sample.md` (light + dark) and of `README.md`
  (30 KB, 0.3 s), checked visually.
- Empty file and binary garbage under `.md`: render without crashing.
- `./build-quicklooks.sh` builds and installs; `pluginkit` lists
  `nl.vincentbruijn.devquicklook.markdown`; `qlmanage -p samples/sample.md`
  launches our `MarkdownPreviewer` process.
- "Folder Quick Look" ships its own Markdown extension; it must be off for ours
  to win (it was off at test time).

**Not done (possible follow-ups)**
- Token-level syntax highlighting inside fenced code blocks (now one green).
- Rounded corners on inline code (AppKit draws text backgrounds square).
- Images are shown as alt text, not loaded.
