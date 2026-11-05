# LuaCJK

A Chinese typesetting package for LuaLaTeX, built on LuaTeX node callbacks.
Everything ships from the single source `LuaCJK.dtx`: three LaTeX packages (`LuaCJK`, `LuaCJKfntef`, `LuaCJK-listings`),
the `ctex` engine file `ctex-engine-luacjk.def`, three Lua modules, the manual
`LuaCJK.pdf`, and `README.md`. `../ctex-kit` is read only, by
`scripts/ctex-subset.sh`, which compiles a subset of the `ctex` test suite
against the engine file.

## Shared rules

Repo etiquette, the git/PR workflow, LaTeX writing and source style,
tooling and upkeep are **machine-global**: see the `repo-rules` skill at
`~/.config/opencode/skills/repo-rules/SKILL.md`. Do not copy them here. The
only local exception is that the manual's prose is English,
so the "no code-like strings in the rendered text" rule is applied
to identifiers and file names only.

The typesetting architecture that the code cannot explain lives in
`.opencode/skills/SKILL.md`; read it before changing the node pipeline, the
punctuation model, the decoration mechanism, or the `ctex` adapter.

## Environment

TeX Live 2026 with LuaLaTeX; no conda. Every command runs from the
repository root, where `build.lua` lives. The maintenance scripts are bash;
Python 3 is available when a task needs it. Entry points:

- `l3build` (unpack, check, save, doc, ctan, tag) for the package itself;
- `scripts/ctex-subset.sh` for the `ctex` integration;
- plain `lualatex` only for throwaway probes — never for regression checking.

## Project layout

| path | what it is |
| --- | --- |
| `LuaCJK.dtx` | the single source: user documentation, the `\changes` history, implementation, and the code of every derived file |
| `LuaCJK.ins` | DocStrip map from the `dtx` blocks to the derived files |
| `build.lua` | `l3build` configuration: module `luacjk`, version `v0.0.1`, `tdslocations`, the `update_tag` hack, `docinit_hook` (copies the generated README back to the root and trims its trailing whitespace), and `tex()`, which runs `latexmk -pdflua` on the `dtx` directly, sets `LUAINPUTS` so that the documentation can load the generated Lua modules, and registers the `glo`→`gls` custom dependency with `makeindex -s gglo.ist`, the only way the change history gets its `.gls`, plus a `changelog` target that regenerates `CHANGELOG.md` from the `\changes` entries with `scripts/extract-changes.lua` |
| `testfiles/NN.lvt` + `.tlg` | 38 regression tests and their baselines, one pair per feature |
| `testsupport/` | files the tests may `\input`: `luacjk-local.cfg` (for `LocalConfig`) and `ctexopts.cfg` (the redirect that makes `ctex01` and the `ctex` subset load the engine file), and nothing else |
| `scripts/ctex-subset.sh` | compiles 21 `ctex` `.lvt` files with the shipped engine file, ignoring their `.tlg` (those are LuaTeX-ja baselines), and appends the redirect to the `ctexopts.cfg` of the `ctex` test tree |
| `scripts/extract-changes.lua` | a Lua port of ctex-kit's `scripts/extract-changes.py`: it turns the `\changes` entries of a `.dtx` into the markdown list of `CHANGELOG.md`.  It takes explicit file names, understands `\keys`, `\oarg` and `\marg`, writes UTF-8 with LF, and names the forge repository of the release link with `--repo` |
| `scripts/check-extract-changes.sh` | regenerates the six changelogs of `../ctex-kit` with the Lua extractor and compares them byte for byte: exit 0 all identical, 1 a difference, 2 cannot run; `--quiet` prints only the differences |
| `scripts/check-docs.sh` | compares the facts in the two guides with their sources: the layout table against `git ls-files` (both directions), version, test count, DocStrip blocks, installed file types, attribute and decoration counts, `\RequirePackage` against `DEPENDS.txt` (a package loaded from the listings guard must be `soft`), `DEPENDS.txt` against `.github/tl_packages`, the subset count, and the changelog facts (the newest `\changes` version and date against `build.lua`, the first line of `CHANGELOG.md` against the released version).  A `\RequirePackage` name is resolved to its TeX Live package with `tlmgr search --global --file`, falling back to `expl3 -> l3kernel` and `l3draw -> l3experimental` when `tlmgr` is absent |
| `.github/workflows/test.yaml` | the CI workflow |
| `.github/tl_packages` | the package list CI installs; a dependency must be added **or removed** here or the Ubuntu job fails first |
| `CHANGELOG.md` | user-visible changes, newest first, generated from the `\changes` entries by `l3build changelog` |
| `LICENSE` | the LPPL text the meta-comment refers to |
| `.gitattributes` | `* text=auto`, so the guides and the `dtx` keep one line ending whichever checkout writes them |
| `DEPENDS.txt` | the TeX Live packages the package needs at run time, one per line as `hard <bundle>` and `soft <bundle>`; `soft` marks a dependency that only an optional output needs |

Generated, never edited by hand: `*.sty`, `*.lua`, `*.def` in the root,
`README.md` (from the `<readme>` block), `CHANGELOG.md` (from the `\changes`
entries), `LuaCJK.pdf`, `*.zip`, `*.glo`, `.codemo.vrb`, `build/`.

DocStrip blocks inside `LuaCJK.dtx`, in file order: `internal`, `readme`,
`driver`, `example` (one guard per demo, so demos can be extracted and run
standalone), `package`, `lua`, `lua-core`, `lua-fntef`, `fntef`, `listings`,
`ctex`.

## Conventions and pitfalls

- **One source.** Edit `LuaCJK.dtx` only; `l3build unpack` regenerates
  everything else. A change to a derived file that is not in the `dtx` is lost
  at the next unpack.
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
  `ctex-engine-luatex.def`: `ctex` installs a file of that name, CTAN rejects
  the duplicate, and kpathsea resolves within one tree by the smallest full
  path, so a same-named copy in `tex/latex/luacjk/` silently loses to the one
  in `tex/latex/ctex/`. `ctex` is redirected through `ctexopts.cfg` instead;
  renaming the file back breaks the redirect without any error.
- **Internal names use `@@`.**  The `dtx` sets `%<@@=LuaCJK>` once, before the
  first implementation line, and every private name is written as
  `\l_@@_…`, `\g_@@_…`, `\c_@@_…`, or `\@@_…`; DocStrip expands the leading
  `@@` to `__LuaCJK`. Documenting them as `\@@_…` lets `l3doc` print the same
  expansion. Never write `@@` inside a Lua block or a Lua string: DocStrip
  rewrites it there too, and the Lua side would no longer match the TeX
  register it looks up. Names that Lua must see are passed in with
  `\cs_to_str:N` (see `LuaCJK.name_ccglue` in the initialization block).
- **Every behavior change needs a test.**  Add or extend a `.lvt`, run
  `l3build save <name>`, then read the `.tlg` diff and confirm the numbers are
  the values you designed, not merely "whatever came out". `save` takes bare
  test names without the extension.
- **Every behavior change also needs a `\changes` entry.**  Put it next to the
  object it changes, inside that object's `macro`, `environment`, or
  `variable`, so `\PrintChanges` files it under the object and prints the page
  it points at; an entry about the manual, the tests, or the repository goes in
  the block after `% \fi` and is filed as `General`.  The version and the date
  stay on the first line and only the text wraps.  Commands are `\cs{…}`, keys
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
- **Three Lua modules, one module table.**  `LuaCJK.lua` only loads the core;
  `LuaCJK-core.lua` owns the load-time state and the passes;
  `LuaCJKfntef.lua` owns the decoration settings, may read what the core
  publishes (`LuaCJK.punct_class`), and must not redefine core behavior.
- **No narration in the Lua code.**  What a function or a pass does is prose in
  the dtx, above its `macrocode` chunk, so it reaches the manual; only a
  comment that explains one expression (a magic number, an invariant) stays as
  a Lua comment. The license header of the three modules comes from
  `\declarepreamble` in `LuaCJK.ins`, not from the dtx body.
- **`l3doc` bookkeeping.**  Follow the global `repo-rules` section "l3doc source
  style": `macrocode` is `%` plus exactly four spaces, every other documentation
  line is `%` plus one space, internal objects are `[int]`, and entries are
  separated by a blank `%` line. A `variable` whose name is a Lua identifier
  (dots, underscores) must carry `[int]`, or the PDF reports an undefined
  reference. Environments documented with `\begin{environment}{...}` in the
  user part must use `environment`, not `macro`, in the implementation part.
- **Fixed names are braces, not metavariables.**  `\tn{begin}\{document\}`,
  not `\tn{begin}\marg{document}` (which prints `{⟨document⟩}`); `\marg*`
  and `\oarg*` do not exist in this `l3doc`. `\file` takes plain text only,
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
  not `\phantom`.
- **The manual describes the package, not the repository.**  No `.lvt` files,
  CI, build commands, or script names in the documentation part: how the
  package is tested and released belongs in this guide, and the principle
  behind an interface belongs in the implementation section, not next to the
  user instruction.
- **`\LuaCJKsetup` gets one sentence.**  Its `function` entry states the
  syntax and that the keys are documented in the following sections; the two
  groups (per-node settings and global or load-time keys) are explained
  outside the environment, and every key is listed once, in the subsection
  that describes it.  A key added to a group in that introduction is a
  second place to forget, so the group lists stay short.
- **Documentation literals.**  Write code points (`U+2018`) rather than the
  characters themselves when the prose would otherwise need a font the manual
  does not set.
- **Demo grouping.**  A demo that declares fonts or char classes must be
  grouped; the `\begingroup`/`\endgroup` pair goes *outside* `codemo` so the
  reader does not see it.

## Workflows

```bash
l3build unpack          # ~5 s, regenerates the derived files
l3build check           # ~3 min, 38 tests, both test runs
l3build check <name>    # one test, the first thing to run after a change
l3build save <name>     # rewrite one baseline after an intended change
l3build doc             # ~2 min, builds the manual and copies README back
l3build ctan            # builds luacjk-ctan.zip
l3build tag             # syncs \GetIdInfo with build.lua's version and date
l3build changelog       # ~2 s, CHANGELOG.md from the dtx \changes entries
bash scripts/ctex-subset.sh            # ~3 min, needs ../ctex-kit or network
bash scripts/ctex-subset.sh --skip-unpack
bash scripts/check-docs.sh             # ~1 s, the guide facts against the code
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

## Validation

- `bash scripts/check-docs.sh` must print `OK: the guides agree with the
  sources`; it is the first thing CI runs and the thing to run before a
  commit that touches a number in either guide, or adds, renames, or removes
  a tracked file (the layout table is compared with `git ls-files` in both
  directions).  The `hard` and `soft` words of `DEPENDS.txt` are what the
  script reads to decide whether a dependency belongs to the package proper
  or only to an optional output, so the word is part of the check, not a
  comment.
- `l3build check` must print `All checks passed`; the `.tlg` baselines must
  match byte for byte. A difference is a behavior change until proven
  otherwise.
- Prove a documentation-only change inert rather than arguing it: unpack from
  a worktree of the previous commit, then `cmp build/unpacked/*` against the
  current build, and compare `mutool draw -F txt` output of the two PDFs. Both
  must be identical, which is the evidence that only prose moved.
- `bash scripts/check-extract-changes.sh` must print six `IDENTICAL` lines.  It
  needs a `../ctex-kit` checkout and judges the Lua extractor against ctex-kit's
  committed changelogs, so a difference means that one of the two moved: run it
  after touching the extractor and when ctex-kit's script has changed.
- `l3build changelog` must leave `git diff --exit-code CHANGELOG.md` clean,
  and `bash scripts/check-docs.sh` checks the changelog facts: the newest
  `\changes` version and date against `build.lua`, and the first line of
  `CHANGELOG.md` against the released version.
- `l3build doc` must finish with no `^!` error, no `Reference ... undefined`,
  and no `Missing character`.  The manual ends with a Change History part;
  it is absent without `LuaCJK.gls`, which only the `glo`→`gls` dependency in
  `tex()` builds, and adding it to the table of contents shifts every page
  reference in the manual by one.
- `bash scripts/ctex-subset.sh` must print `ctex subset: 21/21 passed`, every
  log must be free of `luatexja`, and the script additionally greps for the
  glue strings that prove the `ctex` option plumbing reached LuaCJK.
- The `ctex` baselines cannot be compared: they were produced with LuaTeX-ja
  and describe a different line-breaking implementation, so the subset script
  only compiles the files and checks for the fallback. `ctex01.lvt` covers
  the real path inside `l3build check`, because `testsupport/` holds the
  redirect and the engine file; the subset script needs a `ctex` checkout and
  therefore stays outside the normal run.
- A change that touches the node pipeline should also be checked by hand in
  `build/doc/LuaCJK.pdf` for the affected demo; the extracted examples are the
  fastest place to see the effect.

Session check: `scripts/check-extract-changes.sh`

## CI

`.github/workflows/test.yaml` runs on every push to any branch and on pull
requests. Two jobs, each on `ubuntu-latest`, `macos-latest`, and
`windows-latest`:

- `l3build`: `bash scripts/check-docs.sh`, then `l3build changelog` and a
  `git diff --exit-code CHANGELOG.md` that fails when the generated file is
  stale, then `l3build check`, then `l3build doc` (only if the check passed);
- `ctex-subset`: `l3build unpack`, then `bash scripts/ctex-subset.sh
  --skip-unpack`.

On failure the `l3build` job uploads `build/**/*.diff` and `build/**/*.log` as
`luacjk-diff-<short-sha>-<os>`; download it with `gh run download` through the
proxy (see the `network-access` skill). Local and CI run the same commands;
the only parity risk is a missing or surplus entry in `.github/tl_packages`.

A change in ctex-kit cannot be seen by a workflow of this repository, so it is
not a CI job: `scripts/check-extract-changes.sh` is the session check declared
below, and the `upkeep` plugin of the global configuration runs it once a day
and after a directory change, so a change in the reference implementation
reaches the next session instead of waiting for a pull request.

## Git style

See the global `repo-rules` skill: `type(scope): summary`, commit only when
asked, never commit generated output or secrets. Scopes used in this
repository, one per subsystem: `core`, `fonts`, `chars`, `punct`, `spacing`,
`breaks`, `verbatim`, `options`, `load`, `fntef`, `listings`, `ctex`, `math`,
`manual`, `readme`, `doc`, `build`, `ci`, `layout`, `style`.

expl3 source style — names through `@@`, the interface over the primitive,
hooks, alignment, and spaces around the slashes — is global; see the
`expl3 source style` section of `repo-rules`, not a copy here.
