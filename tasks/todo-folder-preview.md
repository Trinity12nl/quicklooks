# Quick Look for folders: a Finder-style list

## Goal

Space on a folder in Finder shows only a big folder icon. Inge wants what the
app in the screenshot shows (and what Inge bought that app for):

- header: folder icon, name, total size and item count ("492 KB · 3 items")
- a list with columns Name, Date Modified, Size, Kind; file icons; alternating
  row stripes; sortable by clicking a column header
- the path at the bottom as a row of folder icons ("inge › Documents › … › js")

## Decisions (Inge, 2026-11-08)

- Subfolders fold open with disclosure triangles, as in Inge's second
  screenshot (`NSOutlineView`); children load when a folder is opened
- Hidden files: a toggle at the top, off by default; on shows dotfiles
  dimmed. `.DS_Store` is never shown
- Folders only for now; zip/jar/tar keep their text listing (maybe a later PR)

## Approach

A new previewer `FolderPreviewer`, in its own folder like every other format:

- `Sources/Formats/Folder/FolderListing.swift`: reads the folder (name, date,
  size, kind, icon per item; folder sizes summed recursively within a time
  budget, so a huge folder cannot hang the preview)
- `Sources/Formats/Folder/FolderPreviewViewController.swift`: the view, built
  in code: header, `NSOutlineView` with disclosure triangles, hidden-files toggle, path bar
- `build-quicklooks.sh`: one `EXTENSIONS` line claiming `public.folder`

Not a text preview like the others, so it does not use
`TextPreviewController`; nothing shared changes.

## Risks, checked first with a small spike

1. Does macOS give a third-party extension the folder at all? Other apps
   (Folder Preview, the one in the screenshot) do it, so it should, but
   `public.folder` might need `QLIsDataBasedPreview` off or similar.
2. Sandbox: the extension gets access to the previewed URL. Whether that
   includes reading the folder's contents (and sizes of subfolders) has to be
   tested.
3. Packages (`.app`, `.bundle`) are folders too; they keep the macOS preview
   unless we claim them.

If 1 or 2 fails, I come back with what I found before building anything else.

## Todo

- [x] Branch `feature/folder-preview` from `main`
- [x] Spike: minimal extension claiming `public.folder` that lists names.
      Result: `qlmanage -p` on a folder starts FolderPreviewer; it reads the
      folder recursively (in /tmp and in the home folder) and gets icons. No
      extra entitlement needed
- [x] `FolderListing`: items, sizes, kinds, icons
- [x] View: header, columns, stripes, hidden-files toggle, path bar
- [x] Redesign after Inge's test (see Review): one level, no interaction
- [x] Path bar: click a folder to copy its shell-escaped path
- [x] `build-quicklooks.sh`, README, samples note, CHANGELOG
- [x] Verify (renders, `qlmanage -p`, `~/Library`, `~/Documents`), Inge tests
- [ ] Commit, PR on the fork
- [ ] After Inge's go: merge fork PR #7 and this PR, then ONE upstream PR
      for y-a-v-a (Python, SQL, PHP, JS, minified JS, folders) with a
      comment that upstream PR #2 (Markdown) must be merged before it

## Review

First version (outline with fold-open triangles, sortable columns, folder
sizes counted recursively in the background) worked but Inge found it too
slow and fiddly for a Quick Look. Redesigned to match the other app:

- `FolderListing.swift`: `FolderItem` (name, date, kind, size, children) and
  `FolderRow`. The folder is read before the panel opens; each subfolder is
  read one level deep in the background (`concurrentPerform`) and fills in as
  it arrives. A subfolder's size is the sum of the files directly in it;
  deeper folders and packages show "--". At most 200 children per subfolder,
  then "… N more items". Unreadable subfolders say "No access" in red.
- `FolderTable.swift`: read-only `NSTableView` data source (no selection,
  sorting or folding); hidden items dimmed by drawing (a translucent cell
  left the lazily drawn icon blank).
- `FolderPathBar.swift`: `NSPathControl` that copies the clicked folder's
  path, backslash-escaped like a Terminal drop, and flashes "Copied" with a
  Core Animation fade (AppKit's `animator()` fade never showed in Quick Look).
- `FolderPreviewViewController.swift`: header, toggle, table, path bar.
- `build-quicklooks.sh`: `FolderPreviewer` claims `public.folder`.

Found on the way, with evidence:

- Toggle needed two clicks: logged the checkbox's events inside the
  extension; Quick Look delivers a click's mouse up only with the next event,
  so `NSButton` stayed pressed. Fix: act on mouse down (`PressCheckbox`, and
  the path bar). Double-clicking fast still opens the folder: that is Quick
  Look itself, left as is.
- `~/Documents` took 35 s cold: it is iCloud-backed and files are offloaded,
  so reading 128 subfolders waits on iCloud (0.25 s once warm). Hence the
  background read of subfolders; the panel opens in 0.05 to 0.17 s.
- Recursive counting of `~/Library` (300k files in `Caches` alone, 54 s for
  iCloud's `Mobile Documents`) was the reason to drop full folder sizes.
- Inge's purchased "Folder Quick Look" app also claims `public.folder` (and
  Markdown, archives); with it enabled macOS may pick either. Inge disabled it
  for testing.

