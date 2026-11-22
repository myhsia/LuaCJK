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
Noto Serif/Sans CJK SC (a system font, installed by CI's Linux leg from
`.github/font-urls.txt`), with LXGW WenKai GB Lite for the italic and the kai
family and Zhuque Fangsong for the monospaced text and the fangsong family;
both come from the `lxgw-fonts` TeX Live package. The tests keep Fandol,
except the two halfwidth-mark tests of `kinsoku01`, which take LXGW WenKai
because Fandol holds no halfwidth punctuation.
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
| `build.lua` | `l3build` configuration: module `LuaCJK`, version `v0.0.5`, `packtdszip = false` with `tdslocations` kept for `l3build install`, `ctanpkg`, the `uploadconfig` table the CTAN form is read from (its announcement is built from the newest `CHANGELOG.md` section and its note from `CTAN-NOTE.md`), the `update_tag` hack, `docinit_hook` (copies the generated README back to the root and trims its trailing whitespace), and `tex()`, which runs `latexmk -pdflua` on the `dtx` directly, sets `LUAINPUTS` so that the documentation can load the generated Lua modules, and registers the `glo`→`gls` custom dependency with `makeindex -s gglo.ist`, the only way the change history gets its `.gls`, plus a `changelog` target that regenerates `CHANGELOG.md` from the `\changes` entries with `scripts/extract-changes.lua` |
| `testfiles/NN.lvt` + `.tlg` | 77 regression tests and their baselines, one pair per feature |
| `testsupport/` | files the tests may `\input`: `luacjk-local.cfg` (for `LocalConfig`), and nothing else |
| `scripts/ctex-subset.sh` | compiles 21 `ctex` `.lvt` files with the shipped engine file, ignoring their `.tlg` (those are LuaTeX-ja baselines), and appends `engine = luacjk` to the `ctexopts.cfg` of the `ctex` test tree |
| `scripts/extract-changes.lua` | a Lua port of ctex-kit's `scripts/extract-changes.py`: it turns the `\changes` entries of a `.dtx` into the markdown list of `CHANGELOG.md`.  It takes explicit file names, understands `\keys`, `\oarg` and `\marg`, writes UTF-8 with LF, collapses only ASCII whitespace, and names the forge repository of the release link with `--repo`.  It also exports `newest` and `announcement`, which `build.lua` calls to turn the newest section of that changelog into the CTAN announcement |
| `scripts/check-extract-changes.sh` | regenerates the six changelogs of `../ctex-kit` with the Lua extractor and compares them byte for byte: exit 0 all identical, 1 a difference, 2 cannot run; `--quiet` prints only the differences |
| `scripts/check-charclass.lua` | compares the `CJK_RANGES` table of the `dtx` with `Scripts.txt`: it reports every code point whose script is Han, Hiragana, Katakana, Bopomofo, or Hangul that the table does not list, merging the code points into ranges.  The combining Bopomofo tone marks U+02EA and U+02EB are allowed to stay outside the table.  Exit 0 covered, 1 missing (the ranges are printed), 2 cannot run |
| `scripts/check-bilingual.lua` | compares the two `documentation` parts of the `dtx`: the ordered structure (environment nesting, the documented objects and their arguments, section levels, list items) and the multiset of interface references (`\cs`, `\keys`, `\pkg`, `\file`, `\env`, `\tn`, `\val`, `\texttt`, `\meta`, `\oarg`, `\marg`, `\parg` and the `|…|` spans), and refuses a part in the wrong order.  Prose and section titles are not compared.  Exit 0 agree, 1 differ (the differences are printed), 2 cannot run |
| `scripts/check-docs.sh` | compares the facts in the two guides with their sources: the layout table against `git ls-files` (both directions), version, test count, DocStrip blocks, installed file types, attribute and decoration counts, `\RequirePackage` against `DEPENDS.txt` (a package loaded from the listings guard must be `soft`), `DEPENDS.txt` against `.github/tl_packages`, the subset count, the changelog facts (the newest `\changes` version and date against `build.lua`, the first line of `CHANGELOG.md` against the released version), the ranges of the listings character table against the Basic Multilingual Plane part of `CJK_RANGES`, and the two languages of the user part through `scripts/check-bilingual.lua`.  A `\RequirePackage` name is resolved to its TeX Live package with `tlmgr search --global --file`, falling back to `expl3 -> l3kernel` and `l3draw -> l3experimental` when `tlmgr` is absent |
| `scripts/check-test-logs.sh` | reports every TeX error the last `l3build check` left in `build/check/*.log`, one `file:line:text` record per line; exit 0 when every log is clean, 1 when something is printed, 2 when there is no log to read.  The `.tlg` comparison cannot see an error: `nonstopmode` skips the undefined token and the run continues, so a test passes with `! Undefined control sequence` in its log.  Three headlines are expected and allowed, because a test provokes each on purpose: `! OK.` from `\showbox`, the unknown `luaul` key of `fntefopts01`, and the preamble paragraph of `verb02` and `boundary03` |
| `scripts/triage-issues.sh` | lists the open issues that carry no subsystem label.  The type of an issue is GitHub's native issue type (`Bug`, `Feature`, `Task`), which is not a label, so an issue is reported when none of its labels is one of the twenty-one subsystems.  Exit 0 none left, 1 some reported, 2 cannot ask GitHub (no `gh`, no `jq`, not authenticated, no remote, no network).  `--explain` prints the label an ordered keyword table suggests for every open issue, labelled or not, and exits 0; `--apply` adds the suggestion to each issue that has no subsystem label yet and exits 0, or 2 when GitHub refuses an edit; `--number <n>` restricts the run to one issue, which is what the workflow uses so that two runs cannot race.  The table reads the title only, and an issue that matches no rule is printed as `unclassified` and keeps no label |
| `scripts/session-check.sh` | the declared session check, a wrapper because a repository may declare one: it runs `check-extract-changes.sh --quiet` and `triage-issues.sh` and prints one summary line for each that needs attention, so the `upkeep` plugin reports both.  Exit 0 silent, 1 with those lines, 2 only when neither part can run |
| `.github/font-urls.txt` | the Noto CJK release URLs the Linux leg of the `l3build` job downloads for the manual; the hash of the file is the cache key, so changing a URL invalidates the cache |
| `.github/workflows/test.yaml` | the CI workflow |
| `.github/workflows/ctan.yaml` | publishes a release to CTAN: on a published release it checks out the tag, refuses to run unless `build.lua`'s version is the tag's, downloads that release's own `luacjk-ctan.zip` so that the archive CTAN receives is the published one, and runs `l3build upload`; a manual run takes the latest release with the current branch's form |
| `.github/workflows/triage.yaml` | labels and types a new issue: on `issues: opened` and `reopened` it runs `scripts/triage-issues.sh --apply --number <n>`, and once a day (`schedule`) it runs `--apply` over every open issue, filling only what is missing; it needs the default token, `issues: write`; an issue the label table cannot place keeps no label, and the session check reports it |
| `.github/tl_packages` | the package list CI installs; a dependency must be added **or removed** here or the Ubuntu job fails first; the tagged manual and `tagging01` need `latex-lab` and `tagpdf`, and `emoji01` renders `NotoColorEmoji.ttf`, which is `noto-emoji` |
| `CHANGELOG.md` | user-visible changes, newest first, generated from the `\changes` entries by `l3build changelog` |
| `CTAN-NOTE.md` | the internal note of the next CTAN upload, read by `l3build upload` and sent verbatim; empty it once that upload is through |
| `LICENSE` | the LPPL text the meta-comment refers to |
| `.gitattributes` | `* text=auto`; a Windows checkout is CRLF, so a script that reads a source file normalizes `\r\n` before matching a `\n` |
| `DEPENDS.txt` | the TeX Live packages the package needs at run time, one per line as `hard <bundle>` and `soft <bundle>`; `soft` marks a dependency that only an optional output or the default font set needs |

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
  directory and the name of the tds archive), the `tex/` trees in
  `tdslocations`, `uploadconfig.pkg` and `ctanPath`, because CTAN accepts a
  package id in lower case only and rejects an archive whose top directory is
  not exactly that id.
  `l3build` builds `moduledir` from `module` alone — `l3build-variables.lua`
  assigns it unconditionally, after `build.lua` — so the tds tree's `doc/` and
  `source/` directories are `doc/latex/LuaCJK/` and `source/latex/LuaCJK/`,
  while the `tex/` trees follow `tdslocations` and stay lower case.
  That tree is built on every `l3build ctan` and left in `build/tds/`, since
  `packtdszip = false` stops it from being published.
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
- **A code point below U+0100 in a legacy font is a slot, not a character.**
  `LuaCJK.is_cjk` and `punct_class` take the glyph's font as a third argument
  and ask `is_slot`, which caches one answer per font id: `encodingbytes == 2`
  means `luaotfload` loaded a Unicode font, anything else is an encoding, where
  the number that reaches the node is a position in it.  `pifont`'s
  `\ding{183}` is slot 0xB7 of the dingbat font, which would otherwise be read
  as the middle dot and set in the CJK font (or dropped), and slot 0xB7 of a
  T1 text font is `\r{u}`.  A code point above U+00FF cannot be a slot, so a
  CJK character typed in a legacy encoding still takes the CJK font, and a
  Unicode font is read as characters throughout.  Every caller that has a
  glyph passes `.font`; the two math passes and `LuaCJK.punct_class` leave it
  out, because a math noad carries no font.
- **The listings character table is the BMP of `CJK_RANGES`.**
  `\LuaCJK@listings@ranges` repeats the ranges a second time, limited to the
  Basic Multilingual Plane, and `scripts/check-docs.sh` compares the two, so a
  new Unicode release edits both.  The supplementary planes are left out on
  purpose: a definition costs an entry of the string pool, and covering them
  triples it (45 865 strings and 68 881 control sequences become 177 668 and
  200 684) for ideographs a listing almost never holds.  Both loops are
  inclusive, because a mark that opens a range — U+FF01, a curly quote — would
  otherwise come back to `listings`' own character handling, which typesets
  the character the moment it reads it: it lands next to the wrong text and
  counts as one column.
- **A run of CJK characters is one token of `listings`.**  The active
  character appends to `\lst@token` and the run is output only where
  `listings` ends a letter run, so `emph` and `keywords` match a CJK word;
  `\lst@AppendLetter` and `\lst@AppendOther` are wrapped to end it there, and
  the macro each wrapper ends with must be its last token, because
  `\lst@Append` takes the character that follows the active character as its
  argument.  A CJK mark gets a token of its own through
  `\LuaCJK@listings@processpunct`; the marks come from `LuaCJK.punct_codes`,
  which filters the punctuation groups to the table above, so the policy is
  not repeated.  The list reaches TeX through `tex.sprint(-2, …)`, the catcode
  table of other characters: `listings` has made printable ASCII active by
  then, so a digit printed with the current table would not be a number.
  `listings02` pins the colour of every character in each of those cases.
- **The half-width brackets are marks, not Latin punctuation.**  `(`, `[`, and
  `{` are `half-open` and `)`, `]`, and `}` are `half-close`, the only entries
  of `PUNCT_CLASS` outside `CJK_RANGES`: they keep their advance (a compression
  style leaves them alone), never hang, and take the CJK–Latin glue only in
  front of an opening one, so a pair hugs the text between it and offers no
  break inside.  The other ASCII punctuation (`,` `.` `;` `:` `!` `?`) stays
  Latin on purpose, so an English comma keeps the rules of its own script.
  `HalfLeft` and `HalfRight` of `\LuaCJKDeclareCharClass` declare these groups.
- **Every behavior change needs a test.**  Add or extend a `.lvt`, run
  `l3build save <name>`, then read the `.tlg` diff and confirm the numbers are
  the values you designed, not merely "whatever came out". `save` takes bare
  test names without the extension.  A test allocates its boxes with `\newbox`
  instead of numbering them: box 10 is `\voidb@x`, so `\setbox10` is a box the
  next `\leavevmode` unpacks, and `~` expands to `\leavevmode` through
  `\nobreakspace` (`boundary03`).
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
- **A zero length is a length.**  An option whose documented type is
  `length, false` keeps its off state outside the length, in a `_given_`
  boolean beside the `\dim`, because the settings snapshot carries a number
  and `0` would otherwise be indistinguishable from `false`; the Lua side
  then tests the pushed value for truth instead of comparing it.  `PunctWidth`
  and `PunctBoundWidth` are the two that carry one, and `\LuaCJKsetwidth`
  already accepts `0pt` for a single mark.
- **An explicit space is marked at the TeX level.**  A space the document
  writes with `\ ` or `~` and a space from the source reach the spacing pass as
  the same `spaceskip` glue with the same dimensions, so no node comparison can
  tell them apart; `\ ` and `\nobreakspace` therefore set the
  `explicit_space` attribute around the space token, and `handle_source_space`
  leaves a marked glue as it stands.  Both are protected, which is what keeps
  an `\edef` or a `\write` carrying one token, and `\space` is deliberately not
  marked, because it is the form messages use and it has to expand.  The
  aliasing restores the catcode of the space inside a group, since `expl3`
  ignores a space and a control space cannot be written in its syntax.
  A whatsit, a mark, an insertion, or an adjustment between the space and the
  next character is passed over, so the color change `\textcolor` inserts does
  not hide the space: it stays the boundary, and no second glue joins it
  (`boundary03`).  A penalty ends that search, because it has its own rule.
- **Options and `\LuaCJKsetup` share one key path.**  Every key is defined in
  `LuaCJK / options` and read by `\ProcessKeyOptions`, so a new key is a
  package option for free. Do not add a second path or a separate option
  list.  The keys are defined early but the options are read at the end of the
  package, after every helper a key code calls and after the Lua module is
  loaded, because `CJLineBreak` needs the module and the other three — 
  `AutoFallBack`, `CJKmath`, and `PunctFamily` — call helpers of the font
  section; reading them where the key table stands left an undefined control
  sequence in the log and a skipped assignment, so the option acted through
  `\LuaCJKsetup` alone.
- **A CJK math family is built at the text size, not at `\f@size`.**  The
  three style fonts come from `\glb@currsize`, the size LaTeX has installed
  the math fonts for, because `\text` in a formula sets `\f@size` to the
  script size for the `\mathchoice` branches it discards; built there, the
  family would keep that size for the rest of the document.  A fallback font
  used in math is registered as a math family of its own and shares the
  240--255 range with the CJK families, so a document with many of each is
  closer to the sixteen-number limit than its CJK families alone suggest.
- **`LoadFandol` is the base font set, not a per-family default.**  It is on by
  default and acts at `\begin{document}` only when the document declared no CJK
  family at all, so a document that set a font of its own never gets a Fandol
  face it did not ask for; that is xeCJK's rule, and the baselines of the four
  tests that expect `Unknown CJK family 'zhfs'` depend on it.  What a partial
  declaration needs is a diagnosis, not a merge: a document that declared some
  families but not `\CJKfamilydefault` would set its main text in no CJK font
  at all, so `\@@_ensure_family_default:` warns and uses `\CJKrmdefault` or the
  first declared family, and a document that declared nothing with the option
  off is warned about as well.  Its roman family carries
  `FandolKai-Regular.otf` as the italic face, which is what gives `\emph` and
  `\itshape` an effect on CJK text, and the family is declared twice — as the
  main family and as `zhsong` — so both declarations carry the option; the
  other three families have no italic face.
- **The default family is selected when the document starts.**  The hook at
  `\begin{document}` settles `\CJKfamilydefault`: an untouched default follows
  `\familydefault` — `\CJKrmdefault`, `\CJKsfdefault`, or `\CJKttdefault` for
  the matching main family, and `\CJKrmdefault` otherwise — `LoadFandol`
  declares the Fandol faces when the preamble declared nothing, a default that
  no family carries is replaced, and `\@@_reset_family:` then selects the
  surviving family.  Without that last step the main text kept whichever family
  the last `\setCJKfamilyfont` had switched to, while `\normalfont` already
  honoured a redefinition; a preamble that writes
  `\renewcommand{\CJKfamilydefault}{\CJKsfdefault}` therefore set the first
  line in Song and every later `\normalfont` in Hei.  The mapping stores a
  token (`\exp_not:N`), so the default follows a later redefinition of
  `\CJKsfdefault` as well.  `familydefault01` pins the chosen default,
  `familydefault02` the redefined `\familydefault`.
- **A command that takes a family name expands it.**  `\CJKfamily`,
  `\setCJKfamilyfont`, and `\setCJKfallbackfamilyfont` pass the name through
  `\tl_set:Ne`, so a family is named by `\CJKrmdefault` and friends; the
  property key is the expanded name, and a new entry point that skips the
  expansion silently keeps the previous family and warns about the macro.
- **`\CJKfontspec` takes its options before the font name.**  A third optional
  argument would read the bracket the text begins with as its option list and
  swallow it, and the command is used inside the text; the preamble commands
  (`\setCJKmainfont` and its siblings, `\newCJKfontfamily`,
  `\setCJKfallbackfamilyfont`) keep the trailing form, because the text does
  not follow them.  `smoke01` pins the bracket.
- **Every font a family builds takes the default features.**  The list is
  built by `\@@_build_features:n`, and the main font, the font of a sub-block
  (`\@@_register_block_fonts:n`) and a fallback font (`\@@_add_fallback:nn`)
  all go through it; a new place that calls `\fontspec_gset_family` has to
  build the list the same way, or `\defaultCJKfontfeatures` silently misses
  that font.  `fontfeatures01` covers the three.
- **A `Baseline` belongs to the declaration that writes it.**  The value is
  keyed by the declaring family and the `fontspec` family
  (`\g_@@_font_shift_prop`), `\g_@@_shift_pushed_prop` holds the value Lua has
  for each font identifier, and `\@@_push_shift:nnn` hands one over only when
  it changed — a change also clears `\g_@@_fallback_pushed_prop`, so a
  fallback list that shares the instance is resolved again.  One font instance
  carries one offset, so a paragraph takes the value in force when it is
  shaped, which is what lets a fallback font and a family naming the same font
  take turns (`baselineshift01`); the key is
  `<declaring family>|<fontspec family>`, never the identifier alone.
- **A CJK family is selected in the Unicode encoding.**  `\@@_family_font:n`
  sets `\fontencoding{TU}` before `\fontfamily`, and every place that resolves a
  family's font identifier goes through it: `\@@_update_font:` and its
  punctuation family, the fallback chain, the block fonts, the CJK math family,
  and the width the verbatim addon measures.  `fontspec` declares its families
  under `TU`, so a selection made in whatever encoding the document chose finds
  no such shape, warns `Font shape T1/… undefined`, and falls back to the Latin
  text font: `\usepackage[T1]{fontenc}` then sets every CJK character in the T1
  font and reports it missing, and `pifont`'s `U` encoding does the same inside
  its own group.  Resolve a family in `TU`, never in `\f@encoding`.
- **The CJK font is applied before the text is shaped.**  `M.pre_shaping` is
  installed on luaotfload's `pre_shaping_filter`, so the font is set on the
  glyph in place and the font's own features apply: a combining mark attaches
  to its base (`shaping01`), a variation sequence selects its glyph, and a
  font that joins two em dashes does so on its own, which is why the manual no
  longer lists `PoZheHaoLigature` as absent.  The `Baseline` shift is added
  only where the font actually changes, which is what keeps the pass
  idempotent across the paragraph and again on each line packed from it — a
  second copy of the shift would move every shifted line twice.
  What shaping leaves of a joiner, a variation selector, or a CJK character
  the font does not have is removed by `drop_orphans` before the spacing pass;
  it consults `missing_chars`, filled by `pre_shaping`, so the box a document
  with no CJK font shows stays (`loadfandol03`).  A luaotfload without the
  callback keeps the previous path in full — `rewrite_fonts` through
  `copy_glyph` after shaping, and every zero-width character removed at the
  input — and no test reaches it, because a callback type cannot be taken out
  of a live callback list; check that path by hand with a probe against an
  unpacked copy whose `M.shaping` is forced to `false`.
- **A drawn pattern is colored inside its own drawing.**  The ink of the wave
  and the slash is stroked by `l3draw`, which uses the color `l3color` holds,
  so `luacolor`'s attribute never reaches it; an attribute on a leader box whose
  content is a drawing only leaks, because `luacolor` writes the color in front
  of the repeated box and finds no node after it that carries an attribute to
  restore the previous one.  The type is built without `\luaul_apply_color:`,
  and the drawing writes the operations it reads from `\current@color` — the
  resolved `format`, or the color of the text — right after `\draw_begin:`,
  expanded when the box is built, because a literal expands its payload at
  shipout, when the variable belongs to another call.  `fntefcolor01` pins the
  literal in the box and the attribute of the leaders glue.
- **Inserted nodes must inherit attributes.**  Glue, kern, and penalty nodes
  created after TeX attached the attributes need `inherit_attributes(...)`, or
  attribute-driven packages such as `lua-ul` see the span end there.
- **A pass runs again on every box that holds the list.**  `hpack_filter` walks
  a list each time a box is packed from it, so a pass that inserts nodes must
  recognise its own work and leave it alone; the `inserted` attribute is that
  record, and `apply_kinsoku`, `apply_check_single`, and `apply_fixed_widths`
  each read it.  Without the check a fixed-width style gives a mark a second
  compensating kern in a table cell or a parbox, which squeezes the text.
- **A hang is bracketed at a glue break, and the three boundaries without a
  glue are bracketed by hand.**  `hang_bounds` adds the hang to the glue a
  line breaks at, which covers every wrapped line; the first line of a
  paragraph and a line that `\\` forces begin with no glue, so the rule that
  shifts the line goes in front of the opening mark itself, or after the
  `-10000` penalty of the forced break.  The indentation in front of a
  paragraph is an empty box of the width of `\parindent`, not a glue, and the
  first line of a list item begins with the label box, which the list follows
  with a penalty of zero, so `head_lead` walks over both with the whatsit and
  local-paragraph nodes and over a penalty that does not force a break, and
  stops at any other box that has ink and an advance of its own.  The two
  hand-bracketed boundaries are skipped when `\leftskip` carries a fill: a
  centered or flush-right paragraph starts its lines at the centering position
  rather than at the edge of the measure, so the rule would move the whole line
  instead of leaving the blank in a margin that is not there.  The hang at a
  break stays in every case, because the line breaker has already counted it
  when it decides that the mark fits (`hang01`).
- **A Type 2 charstring number belongs to the charstring that holds it.**
  `cff_box` hands the charstring being interpreted to the number reader,
  because a subroutine carries its own operands; read from the outer
  charstring, a glyph that calls a global subroutine runs off the end of the
  wrong string (Latin Modern's quotation marks did, and stopped the run).  The
  deprecated `255` form carries four bytes and is read in full.
- **A Type 2 curve takes four operands.**  `cff_box` reads `hhcurveto`,
  `vvcurveto`, `hvcurveto`, and `vhcurveto` the way the specification defines
  them: four operands per curve, the alternating pair starting on the axis the
  operator's name gives, and the single operand of a four-plus-one run closing
  the last curve on the other axis.  Read three operands per curve, a mark
  whose charstring is drawn that way measured its neighbour's blank: the
  opening double quotation mark of FandolSong stood 1.8pt in the margin
  while its font had 0.6em of blank.
- **Suspension is the verbatim hook.**  `\LuaCJKdisable` and `\LuaCJKenable`
  set the `disabled` attribute, which every pass checks per node; `\verb`,
  `verbatim`, `fancyvrb`, and `lstlisting` are already wired to it. A new
  verbatim-like environment joins that list, or its content is adjusted.
  Suspension suppresses the spacing, not the break: the zero-width boundary
  glue stays at either edge of a suspended run, so `\verb|…|` beside a CJK
  character can end a line and a punctuation mark next to suspended text keeps
  its break opportunity (`verb02`).  A mark that may not begin or end a line
  gets none, because the kinsoku pass skips a break that involves suspended
  material, so the prohibition is applied when the glue is inserted.
  `\LuaCJKVerbAddon` is the one command that clears the attribute inside its own
  group, because the gap it computes is inserted by the spacing pass and a
  suspended node is skipped; it reads the value it found into
  `\l_@@_verb_saved_disabled_int` first, and `\LuaCJKOffVerbAddon` restores it.
  Without that, the addon does nothing in the default verbatim mode, where the
  environment hook has already suspended the material (`verbaddon02`).
  fancyvrb selects `\verbatim@font` nowhere, so its commands were reached by
  neither hook until `\@@_fv_prep_hook:` was prepended to its shared
  `\FV@FormattingPrep`: the inline `\Verb` and `\UseVerb` follow `\verb`'s rule
  and the blocks the environments' rule, told apart by
  `\l_@@_verbatim_block_bool`, which the environment hooks and
  `\FV@UseVerbatim` set.  Neither inline command can be wrapped to mark itself:
  a token after `\Verb` is scanned into its text, and `\FVC@Verb` ends its group
  from inside the box it sets (`fancyvrb01`, `fancyvrb02`).
- **A rule decoration adjusts `lua-ul`, it does not draw.**  `lua-ul` emits a
  leaders glue of width *w*, stretch *st*, and shrink *sh*, followed by a glue
  of width *-w*, stretch *-st*, and shrink *-sh*; the adjustment replaces the
  leaders with kerns and shorter leaders whose widths, stretches, and shrinks
  still add up to *w*, *st*, and *sh*.  Dropping the stretch leaves the line
  with the negative half of the pair, which moves every other word in it, so a
  rule-based decoration must keep the whole invariant.  A piece whose leader
  box holds nothing but one rule gets a rule of zero width, which `\leaders`
  fills to the width of the glue.
- **A decoration's underline type keeps the color and the font size it was
  built with.**  `luacolor` colors a rule by attribute, and `lua-ul` puts the
  attributes of the built box on every leader it inserts, so a type cached by
  geometry alone keeps the color of the first call.  The cache key therefore
  carries the color — the operations that `\luaul_context_color:` holds after
  `\luaul_set_color:n`, which is what `lua-ul` puts in the context of its own
  type, when `format` is set, otherwise the value of `luacolor`'s attribute,
  which is the color of the surrounding text — and the font size, because
  `lua-ul` scans the pattern box once per type, so a pattern written in `em`
  units would otherwise keep the size of the first call.  The key holds the
  resolved operations and not the name the document wrote, because a name can
  be redefined: `\colorlet{mark}{blue}` after `red` must build a second type.
  The `lua-ul` context is the constant `LuaCJKfntef`: the type name already
  carries a counter, while a context that expands again at use time rebuilds
  the type with whatever color is current then.
- **A drawn decoration stays out of the line metrics.**  The wave and the
  xout slash are built at use time in
  `\l_@@_fntef_pattern_box`, which is then set to zero height and depth.
  `l3draw` sizes a box by the stroked bounding box, one stroke width wider than
  the path, and places it by its bottom edge, so the period is forced with
  `\hbox to .5em` plus `\hss` and a path below the baseline is lowered again
  with `\raise`. Without the zeroed box a decoration opens up every decorated
  line.
- **The emphasis dots put their ink in the text.**  A leaders pattern cannot
  follow a character when the inter-character glue stretches and cannot skip
  Latin, so `\CJKunderdot` gives its pair an empty leader box and the pass
  writes one dot behind each CJK character: a zero-width box holding the dot
  shifted by the `depth` key below the em box bottom, with a kern of half the
  advance and half the dot, so the ink is centred and the line keeps its width
  and leading.  A character that the span holds inside a box is dotted as well,
  and the box is entered with the bounds of the whole span, because `subtract`
  and the centre are measured from the start of the span and not from the start
  of the box.  A dot the pass writes carries `LuaCJKfntef.dot`, which is how a
  box that is packed twice is not dotted twice, and it copies the attributes of
  its character, so the dots take the color of their text; `format` replaces
  `luacolor`'s attribute value with the one the TeX side resolved, because a
  rule is colored by attribute.
- **A repeated pattern is written copy by copy by the pass, never repeated by
  `\leaders` and never spread by `\xleaders`.**  `\TeX` repeats only whole
  copies of a leader box, and it aligns them at the left edge of the enclosing
  box rather than at the left edge of the glue, drawing only a copy that lies
  wholly inside the glue: a span that is not a whole number of periods loses one
  at one end, which is what a wave showed whose span ended in the middle of a
  stretched line, and a one-em symbol of an indented character lost every copy,
  because its span began half a cell off that grid.  `\xleaders` is no help
  either: it divides the remainder into glue between two copies, and since a butt
  cap ends where its path ends, every gap is a hole in the stroke as wide as the
  stroke itself.  The `pre_append_to_vlist_filter` pass therefore divides the
  piece into `round(w / period)` whole cells and writes one copy of the leader
  box per cell at `floor(w / k)`, then a kern of the remainder, in place of the
  leaders glue.  Three details make that exact for a drawing: the width is read
  from the line's `glue_set` **and** `glue_sign`, because `glue_set` stays
  positive on a shrunk line; the ink of the copy is painted inside a scope scaled
  horizontally to the cell, because the drawing's period is one em and the cell
  is not; and the closing literal carries `Q` plus `1 0 0 1 <period> 0 cm`,
  because a `q … Q` around the content rewinds the point the backend advances
  from TeX's own bookkeeping.  A copy also drops l3draw's record of the
  drawing's origin, a box of no width that holds nothing but whatsits: every
  copy would record the same label, and the manual then reports `multiply
  defined`.  A symbol is a glyph, which does not scale, so its copy keeps its
  size and is centred in its cell by a kern instead, and that is what
  `\CJKunderanysymbol`, `\CJKunderanyline` and the `symbol` of the wave and the
  dots get.  A leader that is a rule, or a box that reduces to one solid rule, is
  left to `\leaders`, which fills it to the whole width of the glue; the dots
  keep the leader box of no ink they were given; and a box that never reaches a
  vertical list, such as `\hbox to`, keeps the plain `\leaders` remainder.  The
  wave's period is one em and its amplitude a quarter em.
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
- **`CJKfilltwosides` is a `minipage`.**  The environment sets its body in
  `\minipage[position]{width}` inside a group that gives the inter-character
  glue an infinite stretch, and a width of zero or less passes `\linewidth`.
  The body is therefore a parbox whose settings the kernel keeps: `\parindent`
  and `\parskip` are zero, so a paragraph after a paragraph break starts at the
  left edge of the box and is filled like the first; the leading is the
  document's own, which an enclosing alignment would otherwise replace with
  `\lineskip`; `\textwidth` and `\columnwidth` follow the width; the list depth
  restarts; and `\\` is `\@normalcr`, so a cell of a table can hold the
  environment.  A `\footnote` inside is set at the bottom of the box, below the
  rule, and numbered with the box's own counter.  Do not go back to a
  hand-rolled `\vbox`: an insert in a vertical box is discarded at shipout, so
  the note disappears, and every one of those settings would have to be copied
  from the kernel.  The box leaves vertical mode through `\leavevmode`, so the
  text after the environment continues on its line, and a space after `\end` is
  ignored through `\ignorespacesafterend`, as `xeCJK` ignores it.  Under
  tagging, `latex-lab`'s minipage module owns the structure — it ends the
  paragraph around the box, opens a `text-minipage` for the body, and reopens
  the paragraph after it — so the package opens no MC of its own and leaves the
  paragraph hooks alone.
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

  The second reads a log a doc build leaves, so it applies when one exists:
  CI's, downloaded from the failing run, or else a local run made for that
  purpose.
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
- **The package names itself.**  In prose the package is `\pkg{LuaCJK}`, like
  every other package it mentions; a file name is `\file{…}`, and a Lua field
  such as `LuaCJK.settings` is not marked at all.  The `\changes` entries
  follow the same rule, so the generated changelog carries the markup too.
- **Key names.**  An option name in running text is `\keys{name}`, not
  `\texttt{name}`, even outside a `keyval` environment. Inside one it appends
  `=`, so a cross-reference inside a `keyval` description stays `\texttt`.
- **Demos.**  A command without arguments gets no `syntax` block; a command with a
  visible effect gets a `codemo`. In a demo, parallel commands align their
  arguments, a command is not split from the text it affects, and font options
  come before the font name, with the break between the two arguments: the
  option list closes the line and `{font}` opens the next, so a family command
  reads `\setCJKfamilyfont{fam}[options]` then `{font}`.  A length in code drops
  the leading zero (`.3em`) while the prose keeps it (`0.3em`), and a
  line-ending `%` stays only where the space it removes would show in the demo's
  result.  Align a `syntax` continuation with `\` plus spaces, not `\phantom`.
  Three constraints come from `docext` and `l3doc` rather than
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
  by the appendix Implementation; `Fonts` carries six subsections and
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
# the local loop: seconds to a minute
l3build unpack          # ~5 s, regenerates the derived files
l3build check <name>    # one test, the first thing to run after a change
l3build save <name>     # rewrite one baseline after an intended change
l3build changelog       # ~2 s, CHANGELOG.md from the dtx \changes entries
bash scripts/check-docs.sh             # ~1 s, the guide facts against the code
bash scripts/triage-issues.sh          # ~1 s, open issues with no subsystem label
bash scripts/triage-issues.sh --explain  # what the table suggests for every issue
bash scripts/session-check.sh          # ~3 s, the declared session check
texlua scripts/check-charclass.lua     # ~1 s, the CJK range table against Scripts.txt
texlua scripts/check-bilingual.lua     # ~1 s, the two documentation languages

# CI, on every push: the full suite and the manual
l3build check           # ~3 min, 77 tests, both test runs
l3build doc             # ~2 min, tagged manual, needs latex-lab and tagpdf
bash scripts/ctex-subset.sh            # ~3 min, needs ../ctex-kit or network
bash scripts/ctex-subset.sh --skip-unpack

# release time only
l3build tag             # syncs \GetIdInfo with build.lua's version and date
l3build ctan            # ~5 min, check + doc, then both release archives
l3build upload --dry-run  # validates the CTAN form, publishes nothing
```

The three groups are not interchangeable: the first is how a change is verified here,
the second is what CI decides on every push, and the third runs once per release.
A full `l3build check` joins the first only before a push that touches the node
pipeline, `build.lua`, or more than one baseline, because one test cannot see a
baseline broken elsewhere; `l3build doc` joins it when the appearance of a demo is
what is under test.  The global `repo-rules` skill states the rule and its reason.
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
  `LuaCJK.pdf`, and nothing else.  `packtdszip = false` keeps the tds archive
  out of the upload and out of the release; CTAN's TDS guidelines make it
  optional, and a package that spans two `tex/` trees is the case where it is
  useful rather than the case where it is needed.
  The tree itself is still built on every run, from `tdslocations`, and left
  in `build/tds/luacjk.tds.zip`: `l3build-ctan.lua` zips `tdsdir` before it
  consults `packtdszip`, which only decides whether the archive is copied into
  the upload and beside the repository.  It holds the seven installed files
  under `tex/latex/luacjk/` and `tex/luatex/luacjk/`, the sources under
  `source/latex/LuaCJK/`, and the documentation under `doc/latex/LuaCJK/`, so
  it is one `cp` away if a distribution ever asks for it.
- `tdslocations` earns its keep without the archive: `l3build install` and
  `l3build uninstall` place the files with it, `install_files` lays out the
  tds tree with it, and `scripts/check-docs.sh` checks `installfiles` against
  it.
- No archive holds a file the sources generate besides documentation: not
  `*.sty`, `*.lua` or `*.def`, and not `CHANGELOG.md`.
  `scripts/`, `testfiles/`, `testsupport/`, `DEPENDS.txt`, `build.lua`, the CI
  configuration and the repository guides are not part of a release either.
- Every field of the CTAN form comes from `uploadconfig` in `build.lua`, so a
  new release edits that table and nothing else.
  `pkg` is `string.lower(module)`, the id the archive's top directory must
  carry, and `version` is the tag's version as written followed by the release
  date, `v0.0.5 2026-11-22`: CTAN drops the leading `v` when it displays the
  record, and its maintainers ask that the date found in the package files be
  repeated there.  `date` is the one source of it, so `scripts/check-docs.sh`
  keeps the record and the `\changes` history in step.
  `update` is left unset so that `l3build` detects a first release by itself,
  and the topics are `chinese`, `luatex` and `tagged-pdf`.
- Each contact URL is given once.  `repository` carries the checkout and
  `bugtracker` its `/issues`; `home` and `support` are left out because they
  would only repeat that pair, and `development` stays because
  `https://github.com/myhsia` is the owner's page and no other field names it.
  CTAN's maintainers drop the repeated ones themselves and say there is no
  need to fill in every field.
- Two fields are read rather than written.
  `announcement` is built at load time by `scripts/extract-changes.lua` from
  the newest section of `CHANGELOG.md`: a subject line, then that release's
  bullets; when the text would pass the field's 8 192 characters it keeps
  whole bullets and closes with a line naming how many are left and where the
  full list is, so the first release announces 41 of its 46 changes and a
  later one usually passes through untouched.
  `note` is the content of `CTAN-NOTE.md`, sent verbatim as the internal
  message to the CTAN maintainers; an empty file sends none, and the file is
  emptied again once the upload is through, so no note outlives its release.
- `--dry-run` skips the publication step but still posts the archive to
  `https://ctan.org/submit/validate`, so it checks the form and publishes
  nothing.  A rehearsal with no network at all needs a `curl` stand-in on
  `PATH`, as the global `repo-rules` skill describes.
- The submission is `ctan.yaml`, not a local command: publishing a GitHub
  release starts it, it uploads that release's own `luacjk-ctan.zip`, and the
  form and the note come from the same commit as the archive.
  `update` is unset there on purpose — `l3build` sends `true` and falls back
  to `false` when CTAN answers that the package does not exist, so one table
  serves the first release and every later one.
  A manual run takes the latest release with the current branch's form, which
  is how a release cut before the workflow existed is uploaded; the version
  guard is what keeps the two from disagreeing.
  Once CTAN has taken an upload, `CTAN-NOTE.md` is emptied and committed.
- The GitHub release attaches `luacjk-ctan.zip` and `LuaCJK.pdf`, and takes
  the release section of `CHANGELOG.md` as its notes.

This is the one place a full build runs locally. `l3build ctan` is the only
producer of those two assets, and `ctan.yaml` downloads the published archive
rather than building one; the full check and the manual are already green in the
CI run of the commit being tagged, so the run adds the archives and not a second
opinion.

## Validation

- A change is verified here with the local loop: `l3build unpack` and
  `l3build check <name>` for every test the change touches, plus the checks that
  fail in about a second (`scripts/check-docs.sh`, `l3build changelog` and its
  `git diff --exit-code`, `check-charclass.lua`, `check-bilingual.lua`).  The
  full suite, the manual and the `ctex` subset are CI's, on the pushed commit,
  and a report says which side ran what rather than implying the suite passed.
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
  otherwise.  CI runs the full suite on every push, so the whole thing is run
  here only before a push that touches the node pipeline, `build.lua`, or more
  than one baseline.
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
- The manual is held to CI's `doc` step, on the Linux leg: no `^!` error, no
  `Reference ... undefined`, no `Missing character`, and no `multiply defined`
  label or `duplicate destination` warning in `build/doc/LuaCJK.log`: the two
  language parts restart the section numbering, so the `\LuaCJKdoclang` tags are
  what keep their labels and PDF destinations apart.  The manual ends with a
  Change History part; it is absent without `LuaCJK.gls`, which only the
  `glo`→`gls` dependency in `tex()` builds, and adding it to the table of
  contents shifts every page reference in the manual by one.  A doc build is run
  here only to debug a failure that CI reported, and then the log CI kept comes
  first (`gh run download`, see the `ci-artifacts` skill).
- The `docext.sty` that CI's `l3build doc` resolves is v0.2D or later, which
  `kpsewhich docext.sty` and its `\ProvidesPackage` line show.  An older copy
  in `TEXMFHOME` narrows the result panel of a demo whose body is a single
  vertical box, and nothing in the log says so.
- `bash scripts/ctex-subset.sh` must print `ctex subset: 21/21 passed`, every
  log must be free of `luatexja`, and the script additionally greps for the
  glue strings that prove the `ctex` option plumbing reached LuaCJK.  It is a
  CI job only: it needs a `ctex` checkout and three minutes.
- The `ctex` baselines cannot be compared: they were produced with LuaTeX-ja
  and describe a different line-breaking implementation, so the subset script
  only compiles the files and checks for the fallback. `ctex01.lvt` covers
  the real path inside `l3build check`, because it passes `engine = luacjk` to
  the class and so loads the engine file through the public option; the subset
  script needs a `ctex` checkout and therefore stays outside the normal run.
- A change that touches the node pipeline should also be looked at by hand in
  `build/doc/LuaCJK.pdf` for the affected demo, because a demo can typeset
  wrongly and still match its baseline; the extracted examples are the fastest
  place to see the effect.  That is the one reason to build the manual here, so
  the build happens when the appearance is the thing under test rather than
  after every change.
- `bash scripts/session-check.sh` must exit 0 and print nothing: it is the
  declared session check, and it reports a changelog drift against ctex-kit and
  any open issue that still has no subsystem label.  `bash
  scripts/triage-issues.sh` lists those issues itself, exit 0 when there are
  none, 1 when there are, and 2 when `gh` cannot ask GitHub.  A change to the
  keyword table is judged by `--explain` over the current board: every issue the
  table places must land where its report says the fix goes, and an issue it
  cannot place must stay `unclassified` rather than take a near-miss label.

Session check: `scripts/session-check.sh`

## CI

`.github/workflows/test.yaml` runs on every push to any branch and on pull
requests. Two jobs, each on `ubuntu-latest`, `macos-latest`, and
`windows-latest`:

- `l3build`: install TeX Live (with `wintools.windows` on Windows, for
  `unzip`), install the ctex-kit branch with the `engine` option (see below),
  then `bash scripts/check-docs.sh` (it calls
  `texlua` for the bilingual check, so it cannot run before the install),
  then `texlua scripts/check-charclass.lua`, then `l3build changelog` and a
  `git diff --exit-code CHANGELOG.md` that fails when the generated file is
  stale, then `l3build check`, then `bash scripts/check-test-logs.sh`, which
  fails on a TeX error in a test log other than the three a test provokes on
  purpose (`.tlg` comparison cannot see them: `nonstopmode` skips the token).
  The manual is built on the Linux leg only, and only if the check passed:
  it is one artifact judged once, while what the other platforms add is the
  behaviour of the package, not the appearance of its documentation.
  That leg alone downloads the Noto CJK collections listed in
  `.github/font-urls.txt` (cached under the file's hash, copied into the
  system font directory, then `fc-cache -f`), because the manual is their only
  consumer and the tests keep Fandol.
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

CI is the authority for the slow ones — the full suite, the manual and the
`ctex` subset — so a session pushes and reads that run rather than repeating
them here; a local repeat is made only for the two reasons the global
`repo-rules` skill states.

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
proxy (see the `network-access` skill). CI and a local full run work from the
same tooling; a local full run — the manual for a demo's appearance, or
`l3build ctan` at release — gets the same ctex from an `l3build install` of that
branch into `TEXMFHOME` (`~/Library/texmf` on this Mac), and the remaining
parity risks are a missing or surplus entry in `.github/tl_packages` and the
fonts the manual needs (Noto CJK from `.github/font-urls.txt`, the two LXGW
faces from `lxgw-fonts`).

A second workflow, `ctan.yaml`, is not a test: publishing a GitHub release
starts it, and it publishes that release to CTAN.
It checks out the release tag, fails unless `build.lua`'s version is the tag
with the `LuaCJK-` prefix removed, installs nothing but `l3build`, downloads
the release's own `luacjk-ctan.zip` — so the archive CTAN receives is byte for
byte the published one — and runs `l3build upload` with `y` on stdin, because
the upload confirmation is the only prompt a complete form still has.
A manual run uploads the latest release using the current branch's form, which
is how a release published before the workflow existed is submitted; the
version guard is what stops the two from disagreeing.
On failure it keeps `luacjk-ctan.curlopt`, the exact request, as an artifact.

A change in ctex-kit cannot be seen by a workflow of this repository, so it is
not a CI job: `scripts/session-check.sh` is the session check declared below,
and the `upkeep` plugin of the global configuration runs it once a day and after
a directory change, so a change in the reference implementation reaches the next
session instead of waiting for a pull request.  The same wrapper is the only
place a session is told that open issues are still uncategorised, because a
repository may declare one check and not two.

A third workflow, `triage.yaml`, is not a test either: it labels and types an
issue when it is opened or reopened, and once a day it applies the same tables
to every open issue, so one that was missed while the workflow was down — or
that a later rule change places — is completed without a session.  It needs
nothing but the checkout and the default token (`permissions: issues: write`),
and it runs the committed script rather than a copy, so the rule that decides a
label in the absence of a session is the same rule the session check reports
against.

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

A fifth was the font applied to the glyph nodes *after* the text was shaped:
`rewrite_fonts` copied each CJK glyph into the font its attribute named, and
the manual listed the CJK font's OpenType features as a consequence it could
not have.  It was replaced for the two reports that read it from the outside:
a base and a combining mark stayed two glyphs because the copy carries no
position, so `か` + U+3099 came out beside its base while the precomposed `が`
was one glyph, and a joiner never reached the font at all, so an emoji
sequence was split.  What replaces it is the substitution in front of shaping;
copying a shaped glyph cannot carry what shaping decided, and a character the
shaper must see cannot be removed at the input.

A sixth was the body of `CJKfilltwosides` set in a hand-rolled `\vbox` whose
lines were placed by the package: the `t` position rebuilt the vlist as a
`\vtop`, the `c` position centred it on `\Umathaxis\textstyle`, and the body
was tagged as one MC of the paragraph around it, which meant turning the
automatic paragraph hooks off around the box.  It went for two reports that
read the box from the outside: a paragraph after `\par` kept the surrounding
`\parindent` (15pt on the report's two-line box) while `xeCJK`'s minipage
starts at the left edge, and a `\footnote` became an `ins` node that a
vertical box discards at shipout, so the mark printed and the note never did.
What replaces it is `\minipage` itself: the kernel keeps the parbox settings,
the mpfootnote mechanism, and — through `latex-lab`'s minipage module — the
tagged structure, so none of it is copied here.

## Issue triage

Every issue carries **one subsystem label**; its **type** is the native GitHub
issue type (`Bug`, `Feature`, `Task`), which is not a label and is set on
GitHub's side, so nothing here repeats it.

- The subsystem labels are the commit scopes of the "Git style" section below
  (`core`, `fonts`, `chars`, `punct`, `spacing`, `breaks`, `verbatim`,
  `options`, `load`, `fntef`, `listings`, `ctex`, `math`, `manual`, `readme`,
  `doc`, `build`, `ci`, `layout`, `style`, `repo`), all purple.  The label names the
  place the fix lands, so it predicts the scope of the commit that closes the
  issue; `fntef` is therefore right for a report about `LuaCJKfntef`, even when
  the example also mentions a font.
- An open issue that the session finds without a subsystem label or a type is
  completed in that session, before the task it was doing: read the report and
  pick the subsystem from where the fix belongs.  `scripts/triage-issues.sh`
  lists exactly those issues and `scripts/session-check.sh` reports their count
  at the start of a day.
- Most issues never reach that point.  `triage.yaml` runs the same script with
  `--apply` when an issue is opened or reopened **and once a day**, and the
  script's ordered keyword table decides the label: first match wins, so an
  issue that names both `\CJKunderline` and `CJKglue` lands in `fntef`, where
  the fix belongs.  An issue whose title matches no rule is left unlabelled on
  purpose rather than given a guess, which is why the session check still has a
  job: it is the net for the reports the table cannot place.  The daily run is
  the net for the other way an issue misses its label — it was opened while the
  workflow was down, or a later rule change places it — because it applies to
  every open issue and only fills what is missing.
- **The table reads the title, never the body.**  A body is the reporter's
  apparatus, and it is nearly identical across the reports of one reporter —
  every issue here opens with `\usepackage[LoadFandol]{LuaCJK}` and
  `\setCJKmainfont{…}` — so a body scan labelled a question about `lstlisting`
  with `load` (#32) and a question about Japanese combining marks with `fonts`
  (#34).  The title is the part the reporter chose to name the defect with, and
  an option name is a rule only when it is the subject of the report, which
  reading the title enforces.  A consequence worth keeping: a report whose
  title names no subsystem (#33, #34) is unclassified, and a session labels it
  from the body, which is the reading the table is not allowed to do.
- **A session reads a body for the defect, never for the package list.**
  `\usepackage{LuaCJKfntef}` sits in almost every MWE of this board, because
  the reporters load it out of habit, so a label read from the `\usepackage`
  lines is `fntef` for every report: that is how #124 and #129, whose titles
  name the layout environment, were labelled `fntef` after the table had
  correctly declined to place them.  The module a report *loads* is apparatus;
  the command or environment it *fails on* is the subsystem.
- A keyword rule names the *file* the fix touches, never the topic the report
  mentions.  `PunctWidth` is `punct` although the reporter passes it as an
  option, and `LoadFandol` is `load` although it loads fonts, because that is
  where the change goes.  A font feature, and the interface that sets one
  (`\addCJKfontfeatures`, `CharacterWidth`, `hwid`), is `fonts` for the same
  reason, `\hfill` names the glue whose subtype the spacing pass decides, so
  it is `spacing`, and `CJKfilltwosides` is the layout environment, so its
  name is `layout`.
- **A code point is `chars`, and that rule comes last.**  A title whose only
  hook is a code point (`U+2027 的排版`) is about the character table, which is
  where a code point becomes CJK.  First match wins, so the code-point rule is
  the final line of the table: an issue that also names a subsystem
  (`U+0027 的间距`) takes that subsystem, which is where its fix lands.
- **The type comes from its own table, and its default is `Bug`.**  `Bug`,
  `Feature`, and `Task` are set by GitHub and no label stands in for them, so
  `--apply` fills whichever of the two an issue lacks.  A title cannot always
  tell a defect from a request — `不支持` means "this fails" in #29 and "this
  does not exist" in #67 — so only `Task` (`讨论`, `优化`, `是否有可能`) and
  `Feature` (`希望`, `建议`, `新增`, `增加`, `添加`, `新功能`, `feature`) are
  recognised, and everything else is a defect report.  Measured against the 48
  issues a person had already typed, that table is right for 42; the six misses
  are #67, #64, #5 (`Feature` read as `Bug`), #24 (`Bug` read as `Feature`),
  #86 (`Bug` read as `Task`), and #1 (`Feature` read as `Task`).  A wrong type
  is invisible, since nothing reports it, so a session corrects one it reads as
  wrong while it is in the thread.
- **A green triage run does not mean a label was applied.**  `--apply` prints
  `#N unclassified` and exits 0 when no label rule matches, which is the
  designed outcome; the run's own log is the only place that says so.  Read it
  before concluding that the workflow labelled an issue.

**Fixing an issue** follows the global rule in `repo-rules` ("Fixing an
issue"); what is local to this repository is the shape of the work.  The branch
is `fix/<scope>-<topic>`, off `main`, one theme per pull request, and the body
lists every issue that theme closes.  Before the reply, `l3build check` runs on
the tests the change touches, and the `\changes` entry and the regenerated
`CHANGELOG.md` travel in the same commit; `scripts/check-docs.sh` and
`l3build changelog` with a clean diff decide whether the commit is ready, and
the full suite, the manual and the `ctex` subset are CI's.  The before/after
image is rendered here from the merge base — `lualatex` on the report's MWE,
`pdfcrop`, then `mutool draw -r 300` — because the MWE in the report is what
the reader compares with.
An issue whose fix is already on the default branch — the report was filed
against the released version, which the default branch has moved past — takes
its before image from that release and says so in the reply; the pull request
is then a regression test, `chore(scope)` with no `\changes` entry, because
the behaviour is already recorded by the change that shipped it.
The image reaches the issue through a `<scope>-shots` branch of this
repository, one per subsystem: it holds
`docs/screenshots/<scope>/<number>-before.png` and `-after.png`, and the reply
embeds them by their `raw.githubusercontent.com` URL.  A screenshot never goes
on the branch under test.

## Git style

See the global `repo-rules` skill: `type(scope): summary`, commit only when
asked, never commit generated output or secrets. Scopes used in this
repository, one per subsystem: `core`, `fonts`, `chars`, `punct`, `spacing`,
`breaks`, `verbatim`, `options`, `load`, `fntef`, `listings`, `ctex`, `math`,
`manual`, `readme`, `doc`, `build`, `ci`, `layout`, `style`, `repo`.

expl3 source style — names through `@@`, the interface over the primitive,
hooks, alignment, and spaces around the slashes — is global; see the
`expl3 source style` section of `repo-rules`, not a copy here.
