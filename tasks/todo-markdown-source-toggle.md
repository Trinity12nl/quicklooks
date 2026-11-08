# Markdown previewer: toggle between rendered and source

## Goal

A small switch in the Markdown preview to flip between the rendered document
(current behaviour) and the Markdown source, syntax coloured with line
numbers like the other previewers in this project.

## Findings

- A Quick Look preview extension owns its whole view, so it can contain a
  control. The view already takes clicks (links work, text is selectable).
  Finder's small previews (column view, Get Info) may not pass clicks on;
  there the default view simply stays.
- `TextPreviewController` sets the text once in `preparePreviewOfFile`. To
  swap content later it needs one small internal method that (re)displays an
  attributed string; the Markdown controller calls that from the switch.

## Design

- `NSSegmentedControl` with two segments, pinned top-right over the text,
  small control size, so it doesn't push content down.
- Rendered mode: unchanged `MarkdownRenderer`.
- Source mode: new `MarkdownSourceRenderer` (target < 150 lines), line-based
  highlighting in the shared `PreviewStyle` palette with the usual header and
  line-number gutter: headings, emphasis markers, inline code and fences
  (fence content coloured per language via `MarkdownCode`'s table), links,
  list markers, quotes, front matter, HTML comments.
- Both renderings are made once on demand and cached for the open preview.

## Todo

- [x] Spike: verify a button in the preview actually receives clicks in the
      Finder space-bar panel (before building the rest): works (Inge)
- [x] `TextPreviewController`: extract a `display(_:wraps:)` method (no
      behaviour change for other previewers)
- [x] `MarkdownSourceRenderer.swift`
- [x] Switch in `MarkdownPreviewViewController`; always opens in Preview
      (decided by Inge, replacing "remember the last mode")
- [x] Register new source file in `build-quicklooks.sh`
- [x] README paragraph, CHANGELOG entry
- [ ] Render both modes light/dark, build, Inge tests manually
- [ ] Commit on PR #3

## Review

- `TextPreviewController`: `preparePreviewOfFile` now calls a new
  `display(_:wraps:)`, which the Markdown controller calls again to swap
  content. No behaviour change for the other previewers.
- `MarkdownPreviewViewController`: small `NSSegmentedControl` (Preview |
  Source) top-right; each view is rendered once per file on first use; a
  failure shows an error message instead of a blank pane. Always opens in
  Preview.
- `MarkdownSourceRenderer.swift` (new): line-based colouring in the shared
  `PreviewStyle` palette with header and line-number gutter. Only fences,
  front matter and HTML comments carry state across lines, so a stray `*`
  or backtick can't colour the rest of the file. Fence content uses
  `MarkdownCode.syntax(for:)`, the same language table as Preview.
- Verified: harness clicks the real switch (control action) and renders
  Source in light/dark; README (30 KB) 0.34 s; empty and binary files fine.
  Spike confirmed by Inge that the switch receives clicks in Finder.
