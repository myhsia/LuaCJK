# LuaCJK

A Chinese typesetting package for the LuaTeX engine, built on node callbacks.
Everything ships from the single source `LuaCJK.dtx`: three LaTeX packages (`LuaCJK`, `LuaCJKfntef`, `LuaCJK-listings`),
the `ctex` engine file `ctex-engine-luacjk.def`, three Lua modules, the manual
`LuaCJK.pdf`, and `README.md`. `../ctex-kit` is read only, by
`scripts/ctex-subset.sh`, which compiles a subset of the `ctex` test suite
against the engine file.

## Shared rules

Repo etiquette, the git/PR workflow, LaTeX writing and source style,
tooling and upkeep are **machine-global**: see the `repo-rules` skill at
`~/.config/opencode/skills/repo-rules/SKILL.md`. Do not copy them here. The
only local exception is that the manual is bilingual,
so the "no code-like strings in the rendered text" rule is applied
to identifiers and file names only.

The typesetting architecture that the code cannot explain lives in
`.opencode/skills/SKILL.md`; read it before changing the node pipeline, the
punctuation model, the decoration mechanism, or the `ctex` adapter.

## Environment

TeX Live 2026 with LuaLaTeX; no conda. Every command runs from the
repository root, where `build.lua` lives. The maintenance scripts are bash;
Python 3 is available when a task needs it. The manual sets its CJK text in
Noto Serif/Sans CJK SC (a system font, also installed by CI from
`.github/font-urls.txt`), with LXGW WenKai GB Lite for the italic and the kai
family and Zhuque Fangsong for the monospaced text and the fangsong family;
both come from the `lxgw-fonts` TeX Live package. The tests keep Fandol.
The manual is itself a `ctex` document: its driver loads `ctex` with
`engine = luacjk`, `fontset = fandol` and `linespread = 1`, so LuaCJK arrives
through the engine file and the prose takes `ctex`'s glue defaults, which is why
line breaking in the manual differs from a plain LuaCJK document.  The fontset
is explicit because `ctex` would otherwise pick the system's Chinese fonts and
stop on a `windows` runner, which has no SimSun, SimHei, KaiTi or FangSong;
`\LuaCJKdocsetup` replaces all five families afterwards.
Entry points:

- `l3build` (unpack, check, save, doc, tag, changelog, ctan, upload) for the
  package itself;
- `scripts/ctex-subset.sh` for the `ctex` integration;
- plain `lualatex` only for throwaway probes — never for regression checking.

## Project layout

| path | what it is |
| --- | --- |
| `LuaCJK.dtx` | the single source: user documentation, the `\changes` history, implementation, and the code of every derived file |
| `LuaCJK.ins` | DocStrip map from the `dtx` blocks to the derived files |
| `build.lua` | `l3build` configuration: module `LuaCJK`, version `v0.0.1`, `ctanpkg` and `tdslocations`, the `uploadconfig` table the CTAN form is read from (its announcement is built from the newest `CHANGELOG.md` section and its note from `CTAN-NOTE.md`), the `update_tag` hack, `docinit_hook` (copies the generated README back to the root and trims its trailing whitespace), and `tex()`, which runs `latexmk -pdflua` on the `dtx` directly, sets `LUAINPUTS` so that the documentation can load the generated Lua modules, and registers the `glo`→`gls` custom dependency with `makeindex -s gglo.ist`, the only way the change history gets its `.gls`, plus a `changelog` target that regenerates `CHANGELOG.md` from the `\changes` entries with `scripts/extract-changes.lua` |
| `testfiles/NN.lvt` + `.tlg` | 50 regression tests and their baselines, one pair per feature |
| `testsupport/` | files the tests may `\input`: `luacjk-local.cfg` (for `LocalConfig`), and nothing else |
| `scripts/ctex-subset.sh` | compiles 21 `ctex` `.lvt` files with the shipped engine file, ignoring their `.tlg` (those are LuaTeX-ja baselines), and appends `engine = luacjk` to the `ctexopts.cfg` of the `ctex` test tree |
| `scripts/extract-changes.lua` | a Lua port of ctex-kit's `scripts/extract-changes.py`: it turns the `\changes` entries of a `.dtx` into the markdown list of `CHANGELOG.md`.  It takes explicit file names, understands `\keys`, `\oarg` and `\marg`, writes UTF-8 with LF, collapses only ASCII whitespace, and names the forge repository of the release link with `--repo` |
| `scripts/check-extract-changes.sh` | regenerates the six changelogs of `../ctex-kit` with the Lua extractor and compares them byte for byte: exit 0 all identical, 1 a difference, 2 cannot run; `--quiet` prints only the differences |
| `scripts/check-charclass.lua` | compares the `CJK_RANGES` table of the `dtx` with `Scripts.txt`: it reports every code point whose script is Han, Hiragana, Katakana, Bopomofo, or Hangul that the table does not list, merging the code points into ranges.  The combining Bopomofo tone marks U+02EA and U+02EB are allowed to stay outside the table.  Exit 0 covered, 1 missing (the ranges are printed), 2 cannot run |
| `scripts/check-bilingual.lua` | compares the two `documentation` parts of the `dtx`: the ordered structure (environment nesting, the documented objects and their arguments, section levels, list items) and the multiset of interface references (`\cs`, `\keys`, `\pkg`, `\file`, `\env`, `\tn`, `\val`, `\texttt`, `\meta`, `\oarg`, `\marg`, `\parg` and the `|…|` spans), and refuses a part in the wrong order.  Prose and section titles are not compared.  Exit 0 agree, 1 differ (the differences are printed), 2 cannot run |
| `scripts/check-docs.sh` | compares the facts in the two guides with their sources: the layout table against `git ls-files` (both directions), version, test count, DocStrip blocks, installed file types, attribute and decoration counts, `\RequirePackage` against `DEPENDS.txt` (a package loaded from the listings guard must be `soft`), `DEPENDS.txt` against `.github/tl_packages`, the subset count, the changelog facts (the newest `\changes` version and date against `build.lua`, the first line of `CHANGELOG.md` against the released version), and the two languages of the user part through `scripts/check-bilingual.lua`.  A `\RequirePackage` name is resolved to its TeX Live package with `tlmgr search --global --file`, falling back to `expl3 -> l3kernel` and `l3draw -> l3experimental` when `tlmgr` is absent |
| `.github/font-urls.txt` | the Noto CJK release URLs the `l3build` job downloads for the manual; the hash of the file is the cache key, so changing a URL invalidates the cache |
| `.github/workflows/test.yaml` | the CI workflow |
| `.github/tl_packages` | the package list CI installs; a dependency must be added **or removed** here or the Ubuntu job fails first; the tagged manual and `tagging01` need `latex-lab` and `tagpdf` |
| `CHANGELOG.md` | user-visible changes, newest first, generated from the `\changes` entries by `l3build changelog` |
| `CTAN-NOTE.md` | the internal note of the next CTAN upload, read by `l3build upload` and sent verbatim; empty it once that upload is through |
| `LICENSE` | the LPPL text the meta-comment refers to |
| `.gitattributes` | `* text=auto`; a Windows checkout is CRLF, so a script that reads a source file normalizes `\r\n` before matching a `\n` |
| `DEPENDS.txt` | the TeX Live packages the package needs at run time, one per line as `hard <bundle>` and `soft <bundle>`; `soft` marks a dependency that only an optional output needs |

Generated, never edited by hand: `*.sty`, `*.lua`, `*.def` in the root,
`README.md` (from the `<readme>` block), `CHANGELOG.md` (from the `\changes`
entries), `LuaCJK.pdf`, `*.zip`, `*.curlopt`, `*.glo`, `*.gls`, `*.glg`,
`.codemo.vrb`, `build/`.

DocStrip blocks inside `LuaCJK.dtx`, in file order: `internal`, `readme`,
`driver`, `example` (one guard per demo, so demos can be extracted and run
standalone), `package`, `lua`, `lua-core`, `lua-fntef`, `fntef`, `listings`,
`ctex`.

## Conventions and pitfalls

- **One source.** Edit `LuaCJK.dtx` only; `l3build unpack` regenerates
  everything else. A change to a derived file that is not in the `dtx` is lost
  at the next unpack.
- **`LuaCJK` is the module and the package; `pkg` is the CTAN id.**
  `module` is the spelling of everything the package owns: `LuaCJK.dtx`, the
  file names in `tdslocations`, the repository URL, the changelog heading and
  the release tag.
  `build.lua` derives the CTAN side from it with `local pkg =
  string.lower(module)`, and that one feeds `ctanpkg` (the archive's top
  directory and the name of the tds zip), the `tex/` trees in `tdslocations`,
  `uploadconfig.pkg` and `ctanPath`, because CTAN accepts a package id in
  lower case only and rejects an archive whose top directory is not exactly
  that id.
  `l3build` builds `moduledir` from `module` alone — `l3build-variables.lua`
  assigns it unconditionally, after `build.lua` — so the tds zip's `doc/` and
  `source/` directories are `doc/latex/LuaCJK/` and `source/latex/LuaCJK/`,
  while the `tex/` trees follow `tdslocations` and stay lower case.
  For the same reason a file that is installed but missing from
  `tdslocations` lands in `tex/latex/LuaCJK/` beside the others instead of
  being left out, and the extension check in `scripts/check-docs.sh` cannot
  see it: name every installed file in `tdslocations`.  A case change in the
  package name breaks `\usepackage`; one in the tree breaks `l3build zap` or
  the install path, silently.
- **The user part exists in two languages.**  The `documentation`
  environment is written twice, Simplified Chinese first and English second;
  only the prose and the section titles are translated, so every edit to one
  part is an edit to the other in the same task, and
  `scripts/check-bilingual.lua` (run by `scripts/check-docs.sh`) fails when
  they drift.  The Chinese part uses full-width punctuation in running
  prose, with no space before or after a mark and one space around a Latin
  word or code span; a `keyval` item keeps the English shape,
  `\item[\keys{…}]\val{…}:` on one line, and its separator is the ASCII `:`,
  because it belongs to the markup and not to the sentence.  The markup
  commands, their arguments
  (including the `\meta`/`\oarg`/`\marg` parameter names), the environment
  nesting, and the demo code are identical in the two parts.  The Chinese
  part ends with `\setcounter{section}{0}`, and `docext` also restarts the
  counter before every `documentation` environment, so both parts number from
  one; the `\LuaCJKdoclang{zh|en}` call before each
  part sets a tag that becomes a component of `\theHpart` and, through a
  patch of l3doc's `\__codedoc_get_hyper_target:nN` in the driver, of the
  `doc/function/…` labels, because the repeated numbers would otherwise be
  duplicate labels and PDF destinations.  The Implementation part stays
  English.
- **The bilingual front matter is Chinese-first.**  `\contentsname` prints
  `目录\quad Contents` and `\abstractname` prints `摘要 | Abstract`, written
  `摘要 \texttt\textbar\ Abstract`.  The Chinese and English abstract texts
  sit in one `abstract` environment: the Chinese paragraph, then
  `\setlength \parindent {1.5em}\par`, then the English paragraph.  The title
  puts the Chinese line above the English with a bare `\\`, and the `\thanks`
  body is indented one level so the `\url` lines belong to it.  The
  table-of-contents heading also enters the PDF bookmark, which cannot carry
  a skip, so its two forms are given through `\texorpdfstring`: a bare
  `\quad` there brings back the hyperref warning `Token not allowed in a PDF
  string`.
- **A new installed file type needs three edits.**  A file that the package
  installs must appear in `installfiles` (CI installs from it, and `l3build
  check` copies each entry into the test directory), in `tdslocations` (the
  TDS zip and `l3build install`), and in the generated-file list above. A
  file that is generated but missing from `installfiles` reaches no test.
- **A new derived file declares itself in the shared preamble.**
  `\NeedsTeXFormat`, `\RequirePackage { expl3 }`, the single `\GetIdInfo` and
  the `\Provides…` lines live in one block guarded
  `%<*package|fntef|listings|ctex>`.  A new file adds its guard there and one
  description line, followed by its own `\ProvidesExplPackage` or
  `\ProvidesExplFile`; `LuaCJK-listings` keeps the LaTeX2e
  `\ProvidesPackage` and repeats the date, version and description in its
  optional argument.  `l3build tag` rewrites the one `$Id$`, so a second copy
  of the information would silently go stale.
- **The engine file name is fixed.**  It is `ctex-engine-luacjk.def`, never
  `ctex-engine-luatex.def`: `ctex` inputs `ctex-engine-<name>.def` and takes
  `<name>` from its `engine` option, so `engine = luacjk` is what selects
  LuaCJK. `ctex` installs a file named `ctex-engine-luatex.def`, CTAN rejects
  a duplicate, and that file is the one every `ctex` document loads when the
  option is absent, so a same-named copy in `tex/latex/LuaCJK/` either
  collides or silently describes the wrong backend.
- **The engine file refuses `CJKfntef`.**  `ctex`'s own
  `ctex-engine-luatex.def` bans it, because it loads the legacy `CJK` package
  over the family interface the backend owns. With `engine = luacjk` that code
  never runs, so `ctex-engine-luacjk.def` bans it in two orders — already
  loaded (`\cs_if_exist:cT { ver@CJKfntef.sty }`) and requested later (the
  `package/CJKfntef/before` hook) — and the message points at `LuaCJKfntef`.
  `ctex02` traps the critical message by overriding `\msg_critical:nn` and
  ending the run, the technique `../ctex-kit` uses in `engine-option02`.
- **Internal names use `@@`.**  The `dtx` sets `%<@@=LuaCJK>` once, before the
  first implementation line, and every private name is written as
  `\l_@@_…`, `\g_@@_…`, `\c_@@_…`, or `\@@_…`; DocStrip expands the leading
  `@@` to `__LuaCJK`. Documenting them as `\@@_…` lets `l3doc` print the same
  expansion. Never write `@@` inside a Lua block or a Lua string: DocStrip
  rewrites it there too, and the Lua side would no longer match the TeX
  register it looks up. Names that Lua must see are passed in with
  `\cs_to_str:N` (see `LuaCJK.name_ccglue` in the initialization block).
- **A new Unicode version adds ranges, not code.**  `is_cjk` reads one table,
  `CJK_RANGES`; when TeX Live moves to a new Unicode release, run `texlua
  scripts/check-charclass.lua`, paste the ranges it prints into the table with
  their block names, and let `cjkrange01` fix the result.  The table is a
  policy (shared punctuation is CJK, the combining Bopomofo marks are not),
  so the script reports only what a script-based classification would add.
- **Every behavior change needs a test.**  Add or extend a `.lvt`, run
  `l3build save <name>`, then read the `.tlg` diff and confirm the numbers are
  the values you designed, not merely "whatever came out". `save` takes bare
  test names without the extension.
- **Every behavior change also needs a `\changes` entry.**  Put it next to the
  object it changes, inside that object's `macro`, `environment`, or
  `variable`, so `\PrintChanges` files it under the object and prints the page
  it points at; work on the manual, the tests, or the repository gets no entry,
  and the block after `% \fi` holds a package-level feature that has no single
  documented object.  A feature states what it does in the present tense in the
  release that ships it; only a later release says that it now behaves
  differently.  The version and the date
  stay on the first line and only the text wraps.  An unreleased change keeps
  the newest entry's version and date, so `date` in `build.lua` is not
  advanced on its own: `scripts/check-docs.sh` compares the newest entry with
  both fields, and a later date is reachable only through a new version.
  Commands are `\cs{…}`, keys
  `\keys{…}`, packages `\pkg{…}`, files `\file{…}`, environments `\env{…}`,
  other literals `\texttt{…}`, and the two argument forms `\oarg{…}` and
  `\marg{…}`; a bracketed option list is written `\cs{cmd}|[key = …]|` so
  that it stays one code span.  Those are the rules of
  `scripts/extract-changes.lua`, this repository's own port of ctex-kit's
  extractor, and it understands `\keys`, `\oarg` and `\marg`, which the
  original does not.  The line is documentation: written inside `macrocode`,
  DocStrip copies it into the derived file.
- **New options must reach the settings snapshot.**  A key that describes how
  text is set needs an entry in `DEFAULT_SETTINGS`, a parameter of
  `LuaCJK.new_settings`, a field in the signature string, an argument in
  `\@@_settings_push:`, and a read through `settings_of(node)` in Lua.
  Skipping any of the five makes the option global, which contradicts the
  documented grouping.
- **Options and `\LuaCJKsetup` share one key path.**  Every key is defined in
  `LuaCJK / options` and read by `\ProcessKeyOptions`, so a new key is a
  package option for free. Do not add a second path or a separate option
  list.
- **Inserted nodes must inherit attributes.**  Glue, kern, and penalty nodes
  created after TeX attached the attributes need `inherit_attributes(...)`, or
  attribute-driven packages such as `lua-ul` see the span end there.
- **Suspension is the verbatim hook.**  `\LuaCJKdisable` and `\LuaCJKenable`
  set the `disabled` attribute, which every pass checks per node; `\verb`,
  `verbatim`, `fancyvrb`, and `lstlisting` are already wired to it. A new
  verbatim-like environment joins that list, or its content is adjusted.
  Suspension suppresses the spacing, not the break: a punctuation mark next to
  suspended text keeps its zero-width boundary glue, so a line may still end at
  the mark (`verb02`), while an opening mark gets none, because a break after it
  is prohibited and the kinsoku pass cannot see the prohibition across a
  suspended node.
- **A rule decoration adjusts `lua-ul`, it does not draw.**  `lua-ul` emits a
  leaders glue of width *w* followed by a glue of width *-w*; the adjustment
  replaces the leaders with kerns and shorter leaders so that the total stays
  *w*. Any rule-based decoration must keep that invariant.
- **A drawn decoration stays out of the line metrics.**  The wave, the emphasis
  dots, and the xout slash are built at use time in
  `\l_@@_fntef_pattern_box`, which is then set to zero height and depth.
  `l3draw` sizes a box by the stroked bounding box, one stroke width wider than
  the path, and places it by its bottom edge, so the period is forced with
  `\hbox to .5em` plus `\hss` and a path below the baseline is lowered again
  with `\raise`. Without the zeroed box a decoration opens up every decorated
  line.
- **A decoration symbol is not text the reader should copy.**  The glyphs of
  `\CJKunderanysymbol` and of the `symbol` key are wrapped in an
  `ActualText` marked-content sequence whose replacement is `U+200B`; readers
  drop it from the text they extract and select.  `selectable = true` opts out.
  The wrapper is a `pdf_literal` inside the leader box, not a change to the
  body.  Do not try to clone the font instead: a cloned font used in a
  `\leaders` box aborts LuaTeX at shipout.
- **Tagging is document-driven.**  The package never loads `tagpdf`; it checks
  for `\tag_*` and `\tagpdfpara*` with `\cs_if_exist:NT` and does nothing when
  tagging is off.  The manual driver declares
  `\DocumentMetadata{tagging=on}` and loads `latex-lab-testphase-l3doc`.
- **`CJKfilltwosides` tags by mode.**  In vertical mode it opens a
  `text-block` structure; in horizontal mode it emits an MC attached to the
  surrounding paragraph.  A `text-block` inside a paragraph is invalid
  (`P --> P`), so the branch is required.  The automatic paragraph hooks are
  off around the vbox and on again after it.
- **The selection rectangle is not ours.**  A PDF reader derives its height
  from the font's `hhea` ascent and descent.  For Noto Serif CJK SC that is
  1.437em, so the reader's box is taller than the 1em square even though the
  highlight is correct.  Tagging does not change this; do not add code that
  tries to make the selection square.
- **Three Lua modules, one module table.**  `LuaCJK.lua` only loads the core;
  `LuaCJK-core.lua` owns the load-time state and the passes;
  `LuaCJKfntef.lua` owns the decoration settings, may read what the core
  publishes (`LuaCJK.punct_class`), and must not redefine core behavior.
- **No narration in the Lua code.**  What a function or a pass does is prose in
  the dtx, above its `macrocode` chunk, so it reaches the manual; only a
  comment that explains one expression (a magic number, an invariant) stays as
  a Lua comment. The license header of the three modules comes from
  `\declarepreamble` in `LuaCJK.ins`, not from the dtx body. The license block
  and the file list therefore appear twice in the `.ins`, once under `%%` for
  the TeX files and once under `--` for the modules: `\declarepreamble` bakes
  `\MetaPrefix` into the text when it is declared, so the two cannot share one
  declaration, and a file added to the list is added in both copies.
- **`l3doc` bookkeeping.**  Follow the global `repo-rules` section "l3doc source
  style": `macrocode` is `%` plus exactly four spaces, every other documentation
  line is `%` plus one space, internal objects are `[int]`, and entries are
  separated by a blank `%` line. A `variable` whose name is a Lua identifier
  (dots, underscores) must carry `[int]`, or the PDF reports an undefined
  reference. Environments documented with `\begin{environment}{...}` in the
  user part must use `environment`, not `macro`, in the implementation part.
- **Fixed names are braces, not metavariables.**  In a `syntax` block
  `\tn{begin}\{document\}`, not `\tn{begin}\marg{document}` (which prints
  `{⟨document⟩}`); `\marg*` and `\oarg*` do not exist in this `l3doc`.  In
  running prose the same thing is one code span, `|\begin{document}|`, because
  the escaped braces would come out in the text font. `\file` takes plain text only,
  so keep `\meta` outside it. Every line of a `quote` but the last ends
  with `\\`.
- **Check the markup before committing.**  Two greps catch nearly everything:

  ```bash
  grep -nE '^%[ ]{0,3}\\(begin|end)\{macrocode\}' LuaCJK.dtx   # must be empty
  grep -c 'Reference `doc' build/doc/LuaCJK.log                      # must be 0
  ```
- **Line breaks in prose.**  Start a sentence on a new line, and break a long
  sentence at a comma, semicolon, or colon rather than mid-phrase.  The line
  count of a paragraph and its width do not change; only the break points move.
  Code, `syntax` blocks, `quote` blocks, tables, and the braced variable lists
  (the `{ … }` after `\begin{variable}`) are left alone.
- **Spacing in prose.**  One space after a sentence-ending full stop, question
  mark, or exclamation mark, and no trailing space at the end of a line. TeX
  collapses runs of spaces and breaks lines itself, so neither controls the
  output; alignment padding in code, `syntax` blocks, docstrip tables, and
  license boxes stays as it is.
- **Key names.**  An option name in running text is `\keys{name}`, not
  `\texttt{name}`, even outside a `keyval` environment. Inside one it appends
  `=`, so a cross-reference inside a `keyval` description stays `\texttt`.
- **Demos.**  A command without arguments gets no `syntax` block; a command with a
  visible effect gets a `codemo`. In a demo, parallel commands align their
  arguments, a command is not split from the text it affects, and font options
  come before the font name. Align a `syntax` continuation with `\` plus spaces,
  not `\phantom`.  Three constraints come from `docext` and `l3doc` rather than
  from the package: the box is sized by the number of *source* lines, so the
  output must not have more lines than the body (let a decorated line wrap
  instead of adding a `\parbox`); a setting that is read at line breaking
  (`\LuaCJKDeclareCharClass`, `\LuaCJKDeclarePunctClass`,
  `\LuaCJKEditPunctStyle`, `\normalspacedchars`) applies to the whole
  paragraph, so a comparison needs `\par` and not `\\`; and `"` is active in
  `l3doc` and starts `\verb`, so a range list is shown without its optional
  leading quote. Keep a code line within about 40 monospace characters, or the
  left panel is overfull. The panel height and that width are `docext`'s
  business, not this package's: `../docext/AGENTS.md` states them canonically,
  and the two sentences above are only what a demo writer has to obey.
  A demo that covers a glyph takes its geometry from
  `\LuaCJKemdescent` and `1em`, never from the ink: the em box is the one-em
  square a reader selects, while the ink sits some way inside it, by a
  different amount vertically and horizontally. Quote the two bearings
  separately when a number is needed, and do not hard-code them here — they
  belong to the font, not to the package.
- **The manual describes the package, not the repository.**  No `.lvt` files,
  CI, build commands, or script names in the documentation part: how the
  package is tested and released belongs in this guide, and the principle
  behind an interface belongs in the implementation section, not next to the
  user instruction.
- **The user part has a fixed shape, in both languages.**  Five sections
  (Introduction, Loading, Fonts, Text layout, Comparison with xeCJK) followed
  by the appendix Implementation; `Fonts` carries five subsections and
  `Text layout` six, and no section is left with a single subdivision.  A new
  feature joins the theme it belongs to instead of opening a section of its
  own; the `ctex` material stays in Loading, and the decoration commands end
  the Text layout section.  The Chinese part repeats the shape exactly, with
  the translated titles (简介, 加载, 字体, 文本排版, 与 `xeCJK` 的比较).
- **`\LuaCJKsetup` gets one sentence.**  Its `function` entry states the
  syntax and that the keys are documented in the following sections; the two
  groups (per-node settings and global or load-time keys) are explained
  outside the environment, and every key is listed once, in the subsection
  that describes it.  A key added to a group in that introduction is a
  second place to forget, so the group lists stay short.
- **Documentation literals.**  Write code points (`U+2018`) rather than the
  characters themselves when the prose would otherwise need a font the manual
  does not set.
- **Demo grouping is not containment.**  A demo that declares fonts or char
  classes is grouped, and the `\begingroup`/`\endgroup` pair goes *outside*
  `codemo` so the reader does not see it; but the group holds only local
  settings.  `\setCJKmainfont` re-registers the family named by
  `\CJKrmdefault` for the rest of the document, and `AutoFakeBold` and
  `AutoFakeSlant` are global by design, so the driver defines the manual's own
  setup as `\LuaCJKdocsetup` and runs it again through the
  `env/codemo/after` hook.  A new global command used in a demo joins that
  command, or the headings after the demo lose their real bold face.

## Workflows

```bash
l3build unpack          # ~5 s, regenerates the derived files
l3build check           # ~3 min, 50 tests, both test runs
l3build check <name>    # one test, the first thing to run after a change
l3build save <name>     # rewrite one baseline after an intended change
l3build doc             # ~2 min, tagged manual, needs latex-lab and tagpdf
l3build ctan            # ~5 min, check + doc, then both release archives
l3build upload --dry-run  # validates the CTAN form, publishes nothing
l3build tag             # syncs \GetIdInfo with build.lua's version and date
l3build changelog       # ~2 s, CHANGELOG.md from the dtx \changes entries
bash scripts/ctex-subset.sh            # ~3 min, needs ../ctex-kit or network
bash scripts/ctex-subset.sh --skip-unpack
bash scripts/check-docs.sh             # ~1 s, the guide facts against the code
texlua scripts/check-charclass.lua     # ~1 s, the CJK range table against Scripts.txt
texlua scripts/check-bilingual.lua     # ~1 s, the two documentation languages
```

`l3build doc`, `l3build tag` and `l3build changelog` all write into the
working tree: review and commit the README, the `\GetIdInfo` date and
`CHANGELOG.md` with the change that caused them.
`scripts/ctex-subset.sh` clones `ctex-kit` at tag `ctex-v2.6.5` into
`build/ctex-kit` when `../ctex-kit` is absent, so the first run in a fresh
checkout needs the network. `l3build changelog` needs no network and no
interpreter other than `texlua`: the extractor is `scripts/extract-changes.lua`,
and `bash scripts/check-extract-changes.sh` compares it with the six changelogs
of ctex-kit.

## Release

A release is one tag, one GitHub release and one CTAN upload, all from the
same commit, and the tag goes on the commit whose CI run is green.

```bash
l3build tag && l3build changelog   # both must leave `git diff --exit-code` clean
bash scripts/check-docs.sh
l3build ctan                       # check, doc, then the two archives
l3build upload --dry-run           # the form, without publishing it
```

- The tag is `LuaCJK-v<version>`, the spelling the CHANGELOG heading and its
  release link use.
- `l3build ctan` writes `luacjk-ctan.zip`: the flat package directory
  `luacjk/` with `LuaCJK.dtx`, `LuaCJK.ins`, `README.md`, `LICENSE` and
  `LuaCJK.pdf`, and `luacjk.tds.zip` beside it.
  The tds zip holds the seven installed files under `tex/latex/luacjk/` and
  `tex/luatex/luacjk/`, the sources under `source/latex/LuaCJK/`, and the
  documentation under `doc/latex/LuaCJK/`.
  That is the layout CTAN's TDS guidelines prescribe: the archive's top
  directory is the package id, and the tds zip lies at the top level, where
  CTAN puts it below `install/`.  It is there because the package spans two
  `tex/` trees; a package with one tree would not need one.
- No archive holds a file the sources generate besides documentation: not
  `*.sty`, `*.lua` or `*.def`, and not `CHANGELOG.md`.
  `scripts/`, `testfiles/`, `testsupport/`, `DEPENDS.txt`, `build.lua`, the CI
  configuration and the repository guides are not part of a release either.
- Every field of the CTAN form comes from `uploadconfig` in `build.lua`, so a
  new release edits that table and nothing else.
  `pkg` is `string.lower(module)`, the id the archive's top directory must
  carry, `version` drops the tag's leading `v`, `update` is `false` only for
  the first release, and the topics are `chinese`, `luatex` and `tagged-pdf`.
- Two fields are read rather than written.
  `announcement` is built at load time from the newest section of
  `CHANGELOG.md`: a subject line, then that release's bullets; when the text
  would pass the field's 8 192 characters it keeps whole bullets and closes
  with a line naming how many are left and where the full list is, so the
  first release announces 41 of its 46 changes and a later one usually passes
  through untouched.
  `note` is the content of `CTAN-NOTE.md`, sent verbatim as the internal
  message to the CTAN maintainers; an empty file sends none, and the file is
  emptied again once the upload is through, so no note outlives its release.
- `--dry-run` skips the publication step but still posts the archive to
  `https://ctan.org/submit/validate`, so it checks the form and publishes
  nothing.  A rehearsal with no network at all needs a `curl` stand-in on
  `PATH`, as the global `repo-rules` skill describes.
- The GitHub release attaches `luacjk-ctan.zip`, `luacjk.tds.zip` and
  `LuaCJK.pdf`, and takes the release section of `CHANGELOG.md` as its notes.

## Validation

- `bash scripts/check-docs.sh` must print `OK: the guides agree with the
  sources`; it is the first thing CI runs and the thing to run before a
  commit that touches a number in either guide, or adds, renames, or removes
  a tracked file (the layout table is compared with `git ls-files` in both
  directions, skipping the guide itself, the version-control metadata and the
  generated README, which the table lists in prose rather than as a row).  It
  also runs `scripts/check-bilingual.lua`, so a change to one language of the
  user part without the other fails here.  A `\RequirePackage` name is
  resolved with `tlmgr search --global --file`, whose pattern matches anywhere
  in the path, so the lookup anchors on the file name: a bare `expl3.sty`
  would also find `blx-case-expl3.sty`.  The `hard` and
  `soft` words of `DEPENDS.txt` are what the
  script reads to decide whether a dependency belongs to the package proper
  or only to an optional output, so the word is part of the check, not a
  comment.
- `l3build check` must print `All checks passed`; the `.tlg` baselines must
  match byte for byte. A difference is a behavior change until proven
  otherwise.
- Prove a documentation-only change inert rather than arguing it: unpack from
  a worktree of the previous commit, then `cmp build/unpacked/*` against the
  current build, and compare `mutool draw -F txt` output of the two PDFs. Both
  must be identical, which is the evidence that only prose moved.  A change
  that adds or edits one language of the user part moves the PDF by design;
  the evidence is then the identical derived files plus the unchanged text of
  the other language.
- `bash scripts/check-extract-changes.sh` must print six `IDENTICAL` lines.  It
  needs a `../ctex-kit` checkout and judges the Lua extractor against ctex-kit's
  committed changelogs, so a difference means that one of the two moved: run it
  after touching the extractor and when ctex-kit's script has changed.
- `l3build changelog` must leave `git diff --exit-code CHANGELOG.md` clean,
  and `bash scripts/check-docs.sh` checks the changelog facts: the newest
  `\changes` version and date against `build.lua`, and the first line of
  `CHANGELOG.md` against the released version.
- `l3build doc` must finish with no `^!` error, no `Reference ... undefined`,
  no `Missing character`, and no `multiply defined` label or
  `duplicate destination` warning: the two language parts restart the section
  numbering, so the `\LuaCJKdoclang` tags are what keeps their labels and PDF
  destinations apart.  The manual ends with a Change History part;
  it is absent without `LuaCJK.gls`, which only the `glo`→`gls` dependency in
  `tex()` builds, and adding it to the table of contents shifts every page
  reference in the manual by one.
- The `docext.sty` that `l3build doc` resolves is v0.2D or later, which
  `kpsewhich docext.sty` and its `\ProvidesPackage` line show.  An older copy
  in `TEXMFHOME` narrows the result panel of a demo whose body is a single
  vertical box, and nothing in the log says so.
- `bash scripts/ctex-subset.sh` must print `ctex subset: 21/21 passed`, every
  log must be free of `luatexja`, and the script additionally greps for the
  glue strings that prove the `ctex` option plumbing reached LuaCJK.
- The `ctex` baselines cannot be compared: they were produced with LuaTeX-ja
  and describe a different line-breaking implementation, so the subset script
  only compiles the files and checks for the fallback. `ctex01.lvt` covers
  the real path inside `l3build check`, because it passes `engine = luacjk` to
  the class and so loads the engine file through the public option; the subset
  script needs a `ctex` checkout and therefore stays outside the normal run.
- A change that touches the node pipeline should also be checked by hand in
  `build/doc/LuaCJK.pdf` for the affected demo; the extracted examples are the
  fastest place to see the effect.

Session check: `scripts/check-extract-changes.sh`

## CI

`.github/workflows/test.yaml` runs on every push to any branch and on pull
requests. Two jobs, each on `ubuntu-latest`, `macos-latest`, and
`windows-latest`:

- `l3build`: install TeX Live (with `wintools.windows` on Windows, for
  `unzip`), install the ctex-kit branch with the `engine` option (see below),
  and the Noto CJK collections listed in `.github/font-urls.txt`
  (cached under the file's hash, copied into the system font directory, then
  `fc-cache -f`), then `bash scripts/check-docs.sh` (it calls
  `texlua` for the bilingual check, so it cannot run before the install),
  then `texlua scripts/check-charclass.lua`, then `l3build changelog` and a
  `git diff --exit-code CHANGELOG.md` that fails when the generated file is
  stale, then `l3build check`, then `l3build doc` (only if the check passed).
  The doc step does not trust latexmk's exit code: latexmk counts LuaTeX's
  `unreferenced destination` warning as a broken reference, and
  `latex-lab-testphase-l3doc` creates four such destinations for the name
  tables of function environments, which stalled the Windows runner before it
  converged. The step warns when `l3build doc` exits nonzero and then applies
  the manual's own criteria to `build/doc/LuaCJK.log` — a non-empty PDF, and
  no `^!`, no `[Rr]eference .* undefined`, no `Missing character`, no
  `multiply defined`, no `duplicate destination`;
- `ctex-subset`: install TeX Live and the same ctex-kit branch, then
  `l3build unpack`, then `bash scripts/ctex-subset.sh --skip-unpack`.

Both jobs install ctex-kit's `feat/1122-engine-option` branch into `TEXMFHOME`
before anything is compiled: the package and the manual select the backend with
ctex's `engine` option, which ctex 2.6.6 adds and TeX Live 2026 does not ship
yet. The step clones that branch and runs `l3build install` in its `ctex`
directory, which unpacks by itself and writes into `TEXMFHOME`; kpathsea
searches that tree before `texmf-dist`, so no `sudo` and no `texhash` are
needed and the same commands work on all three systems. The branch is tracked
at its head. **Delete both steps, and nothing else, once ctex 2.6.6 is in TeX
Live**; the condition on the doc step stays as it is.

On failure the `l3build` job uploads `build/**/*.diff`, `build/**/*.fc` and
`build/**/*.log` as
`luacjk-diff-<short-sha>-<os>`; download it with `gh run download` through the
proxy (see the `network-access` skill). Local and CI run the same commands; a
local run gets the same ctex from an `l3build install` of that branch into
`TEXMFHOME` (`~/Library/texmf` on this Mac), and the remaining parity risks are
a missing or surplus entry in `.github/tl_packages` and the fonts the manual
needs (Noto CJK from `.github/font-urls.txt`, the two LXGW faces from
`lxgw-fonts`).

A change in ctex-kit cannot be seen by a workflow of this repository, so it is
not a CI job: `scripts/check-extract-changes.sh` is the session check declared
below, and the `upkeep` plugin of the global configuration runs it once a day
and after a directory change, so a change in the reference implementation
reaches the next session instead of waiting for a pull request.

## Superseded decisions

Three ideas were tried and dropped; they are recorded so that a later session
does not rebuild them. The shadow engine file (a test-only copy of
`ctex-engine-luatex.def` dropped into the working directory) was how the
`ctex` path was tested before `ctex` took the `engine` option: there is now
one engine file with a fixed name and one redirect in `ctexopts.cfg`, and a
second file of any name either collides with `ctex`'s own or loses to it in
the TDS. The lowercase `luacjk.sty` alias was offered for the old spelling of
the package and removed: two names for one file drift apart, and a
case-sensitive file system lets one of them rot unnoticed. The `LuaTeX-CN`
conflict check (`ver@luatex-cn.sty`, and a `package/luatex-cn/before` hook) was
removed as well: LuaCJK rejects `luatexja` because that package owns the same
engine callback layer, but a third-party package that collides with LuaCJK is
its own business to detect, and blocking it here would freeze a decision the
CTeX maintainers have not made.

A fourth took three attempts. `module = "LuaCJK"` alone made `l3build ctan`
write `LuaCJK/` and `LuaCJK.tds.zip`, which CTAN rejects: the package id is
lower case only, and it has to be the archive's top directory.  Putting the id
*in* `module` fixed the archive but dragged the tag, the repository URL and
the changelog heading to a lower-case name, and it moved the tds zip's `doc/`
and `source/` directories to `luacjk/`, since `moduledir` is built from
`module`.  The settled form keeps `module = "LuaCJK"` for everything the
package owns and derives the id as `pkg = string.lower(module)`, which
`ctanpkg = pkg` carries to the archive's top directory and to
`uploadconfig.pkg`.  The price is two mixed-case directories inside the tds
zip, `doc/latex/LuaCJK/` and `source/latex/LuaCJK/`; lower case there would
need `moduledir`, which `l3build-variables.lua` assigns unconditionally after
`build.lua` is read.

## Git style

See the global `repo-rules` skill: `type(scope): summary`, commit only when
asked, never commit generated output or secrets. Scopes used in this
repository, one per subsystem: `core`, `fonts`, `chars`, `punct`, `spacing`,
`breaks`, `verbatim`, `options`, `load`, `fntef`, `listings`, `ctex`, `math`,
`manual`, `readme`, `doc`, `build`, `ci`, `layout`, `style`.

expl3 source style — names through `@@`, the interface over the primitive,
hooks, alignment, and spaces around the slashes — is global; see the
`expl3 source style` section of `repo-rules`, not a copy here.
