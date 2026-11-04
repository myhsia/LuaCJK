# LuaCJK

A Chinese typesetting package for LuaLaTeX, modelled on `xeCJK` and built on
LuaTeX node callbacks.  Everything ships from the single source `LuaCJK.dtx`:
three LaTeX packages (`LuaCJK`, `LuaCJKfntef`, `LuaCJK-listings`), the `ctex`
engine file `ctex-engine-luacjk.def`, three Lua modules, the manual
`LuaCJK.pdf`, and `README.md`.  `../ctex-kit` is read only, by
`scripts/ctex-subset.sh`, which compiles a subset of the `ctex` test suite
against the engine file.

## Shared rules

Repo etiquette, the git/PR workflow, LaTeX writing and source style, tooling
and upkeep are **machine-global**: see the `repo-rules` skill at
`~/.config/opencode/skills/repo-rules/SKILL.md`.  Do not copy them here.  The
only local exception is that the manual's prose is English, so the
"no code-like strings in the rendered text" rule is applied to identifiers and
file names only.

The typesetting architecture that the code cannot explain lives in
`.opencode/skills/SKILL.md`; read it before changing the node pipeline, the
punctuation model, the decoration mechanism, or the `ctex` adapter.

## Environment

TeX Live 2026 with LuaLaTeX; no conda, no Python.  Every command runs from the
repository root, where `build.lua` lives.  Entry points:

- `l3build` (unpack, check, save, doc, ctan, tag) for the package itself;
- `scripts/ctex-subset.sh` for the `ctex` integration;
- plain `lualatex` only for throwaway probes — never for regression checking.

## Project layout

| path | what it is |
| --- | --- |
| `LuaCJK.dtx` | the single source: user documentation, implementation, and the code of every derived file |
| `LuaCJK.ins` | DocStrip map from the `dtx` blocks to the derived files |
| `build.lua` | `l3build` configuration: module `luacjk`, version `0.1.0`, `tdslocations`, the `update_tag` hack, `docinit_hook` (copies the generated README back to the root), and `tex()` (runs `latexmk` with the `l3doc` index style) |
| `testfiles/NN.lvt` + `.tlg` | 37 regression tests and their baselines, one pair per feature |
| `testsupport/` | files the tests may `\input`: `luacjk-local.cfg` (for `LocalConfig`), `ctexopts.cfg` (the redirect used by the `ctex` subset), and nothing else |
| `scripts/ctex-subset.sh` | compiles 21 `ctex` `.lvt` files with the shipped engine file, ignoring their `.tlg` (those are LuaTeX-ja baselines) |
| `.github/workflows/test.yaml` | the CI workflow |
| `.github/tl_packages` | the package list CI installs; a new dependency must be added here or the Ubuntu job fails first |
| `CHANGELOG.md` | user-visible changes, newest first |
| `DEPENDS.txt` | the TeX Live packages the package needs at run time |

Generated, never edited by hand: `*.sty`, `*.lua`, `*.def` in the root,
`README.md` (from the `<readme>` block), `LuaCJK.pdf`, `*.zip`, `*.glo`,
`.codemo.vrb`, `build/`.  `test/` is gitignored scratch space for ad-hoc
compilation; leave whatever is there alone.

DocStrip blocks inside `LuaCJK.dtx`, in file order: `internal`, `readme`,
`driver`, `example` (one guard per demo, so demos can be extracted and run
standalone), `package`, `lua`, `lua-core`, `lua-fntef`, `fntef`, `listings`,
`ctex`.

## Conventions and pitfalls

- **One source.** Edit `LuaCJK.dtx` only; `l3build unpack` regenerates
  everything else.  A change to a derived file that is not in the `dtx` is lost
  at the next unpack.
- **Every behaviour change needs a test.**  Add or extend a `.lvt`, run
  `l3build save <name>`, then read the `.tlg` diff and confirm the numbers are
  the values you designed, not merely "whatever came out".  `save` takes bare
  test names without the extension.
- **New options must reach the settings snapshot.**  A key that describes how
  text is set needs an entry in `DEFAULT_SETTINGS`, a parameter of
  `LuaCJK.new_settings`, a field in the signature string, an argument in
  `\LuaCJK_settings_push:`, and a read through `settings_of(node)` in Lua.
  Skipping any of the five makes the option global, which contradicts the
  documented grouping.
- **Inserted nodes must inherit attributes.**  Glue, kern, and penalty nodes
  created after TeX attached the attributes need `inherit_attributes(...)`, or
  attribute-driven packages such as `lua-ul` see the span end there.
- **The decorations adjust `lua-ul`, they do not draw.**  `lua-ul` emits a
  leaders glue of width *w* followed by a glue of width *-w*; the adjustment
  replaces the leaders with kerns and shorter leaders so that the total stays
  *w*.  Any new decoration must keep that invariant.
- **Two Lua modules, one module table.**  `LuaCJK-core.lua` owns the load-time
  state and passes; `LuaCJKfntef.lua` may read `LuaCJK.punct_class` but must not
  redefine core behaviour.
- **No narration in the Lua code.**  What a function or a pass does is prose in
  the dtx, above its `macrocode` chunk, so it reaches the manual; only a
  comment that explains one expression (a magic number, an invariant) stays as
  a Lua comment.  The licence header of the three modules comes from
  `\declarepreamble` in `LuaCJK.ins`, not from the dtx body.
- **`l3doc` bookkeeping.**  Follow the global `repo-rules` section "l3doc source
  style": `macrocode` is `%` plus exactly four spaces, every other documentation
  line is `%` plus one space, internal objects are `[int]`, and entries are
  separated by a blank `%` line.  A `variable` whose name is a Lua identifier
  (dots, underscores) must carry `[int]`, or the PDF reports an undefined
  reference.  Environments documented with `\begin{environment}{...}` in the
  user part must use `environment`, not `macro`, in the implementation part.
- **Fixed names are braces, not metavariables.**  `\tn{begin}\{document\}`,
  not `\tn{begin}\marg{document}` (which prints `{⟨document⟩}`); `\marg*`
  and `\oarg*` do not exist in this `l3doc`.  `\file` takes plain text only,
  so keep `\meta` outside it.  Every line of a `quote` but the last ends
  with `\\`.
- **Check the markup before committing.**  Two greps catch nearly everything:

  ```bash
  grep -nE '^%[ ]{0,3}\\(begin|end)\{macrocode\}' LuaCJK.dtx   # must be empty
  grep -c 'Reference `doc' build/doc/LuaCJK.log                      # must be 0
  ```
- **Demos.**  A command without arguments gets no `syntax` block; a command with a
  visible effect gets a `codemo`.  In a demo, parallel commands align their
  arguments, a command is not split from the text it affects, and font options
  come before the font name.  Align a `syntax` continuation with `\` plus spaces,
  not `\phantom`.
- **The manual describes the package, not the repository.**  No `.lvt` files,
  CI, build commands, or script names in the documentation part: how the
  package is tested and released belongs in this guide, and the principle
  behind an interface belongs in the implementation section, not next to the
  user instruction.
- **Documentation literals.**  Write code points (`U+2018`) rather than the
  characters themselves when the prose would otherwise need a font the manual
  does not set.
- **Demo grouping.**  A demo that declares fonts or char classes must be
  grouped; the `\begingroup`/`\endgroup` pair goes *outside* `codemo` so the
  reader does not see it.

## Workflows

```bash
l3build unpack          # ~5 s, regenerates the derived files
l3build check           # ~3 min, 37 tests, both test runs
l3build save <name>     # rewrite one baseline after an intended change
l3build doc             # ~2 min, builds the manual and copies README back
l3build ctan            # builds luacjk-ctan.zip
l3build tag             # syncs \GetIdInfo with build.lua's version and date
bash scripts/ctex-subset.sh            # ~3 min, needs ../ctex-kit or network
bash scripts/ctex-subset.sh --skip-unpack
```

`l3build doc` and `l3build tag` both write into the working tree: review and
commit the README and the `\GetIdInfo` date with the change that caused them.
`scripts/ctex-subset.sh` clones `ctex-kit` at tag `ctex-v2.6.5` into
`build/ctex-kit` when `../ctex-kit` is absent, so the first run in a fresh
checkout needs the network.

## Validation

- `l3build check` must print `All checks passed`; the `.tlg` baselines must
  match byte for byte.  A difference is a behaviour change until proven
  otherwise.
- `l3build doc` must finish with no `^!` error, no `Reference ... undefined`,
  and no `Missing character`.
- `bash scripts/ctex-subset.sh` must print `ctex subset: 21/21 passed`, every
  log must be free of `luatexja`, and the script additionally greps for the
  glue strings that prove the `ctex` option plumbing reached LuaCJK.
- The `ctex` baselines cannot be compared: they were produced with LuaTeX-ja
  and describe a different line-breaking implementation, so the subset script
  only compiles the files and checks for the fallback.  `ctex01.lvt` covers
  the real path inside `l3build check`, because `testsupport/` holds the
  redirect and the engine file; the subset script needs a `ctex` checkout and
  therefore stays outside the normal run.
- A change that touches the node pipeline should also be checked by hand in
  `build/doc/LuaCJK.pdf` for the affected demo; the extracted examples are the
  fastest place to see the effect.

## CI

`.github/workflows/test.yaml` runs on every push to any branch and on pull
requests.  Two jobs, each on `ubuntu-latest`, `macos-latest`, and
`windows-latest`:

- `l3build`: `l3build check`, then `l3build doc` (only if the check passed);
- `ctex-subset`: `l3build unpack`, then `bash scripts/ctex-subset.sh
  --skip-unpack`.

On failure the `l3build` job uploads `build/**/*.diff` and `build/**/*.log` as
`luacjk-diff-<short-sha>-<os>`; download it with `gh run download` through the
proxy (see the `network-access` skill).  Local and CI run the same commands;
the only parity risk is a missing entry in `.github/tl_packages`.

## Git style

See the global `repo-rules` skill: `type(scope): summary`, commit only when
asked, never commit generated output or secrets.  Scopes used in this
repository: `core`, `fonts`, `chars`, `punct`, `spacing`, `breaks`, `verbatim`,
`options`, `load`, `fntef`, `listings`, `ctex`, `build`, `ci`, `docs`.
