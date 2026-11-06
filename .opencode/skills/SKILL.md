---
name: luacjk
description: Use when changing LuaCJK's typesetting pipeline — the node passes and attributes, the punctuation model, the LuaCJKfntef decoration adjustment, or the ctex engine adapter.
license: MIT
compatibility: opencode
metadata:
  audience: maintainers
  scope: project
---

# LuaCJK

LuaCJK sets Chinese text through LuaTeX node callbacks:
a CJK glyph carries its font in a LuaTeX attribute and is replaced before
line breaking and box packing. This skill carries the architecture:
which callback does what, what each attribute means, how a punctuation
style is expressed, and why the decorations are adjusted rather than drawn.
It exists so that a change to the pipeline does not have
to be reverse-engineered from the Lua source first.

## Repository rules

Repo etiquette, the git/PR workflow, LaTeX style, tooling and upkeep are
**machine-global**: see the `repo-rules` skill. Build commands, the file
layout, and the validation criteria are in the repository's `AGENTS.md`.

## Background

### Passes and where they run

The character-level passes run in `pre_linebreak_filter` and in
`hpack_filter` (the source is `local function process`):

1. `rewrite_fonts` — point each CJK glyph at the font family recorded on it
   (`\g_@@_font_attr`), then at the punctuation family or a sub-block font
   if one applies, then at a fallback font when the target lacks the glyph.
2. `spacing` — remove the source space between CJK characters, and insert
   `CJKglue`/`CJKecglue` at every boundary between two classes of character.
   A box is an atom, and the class at its edge is the class of the node *at*
   that edge: filling glue (`\numberline`'s `\hfil`), a kern, or a rule means
   the box has no text there, so no glue is added beside it, while a box of no
   size is passed over (`boundary01`).  Taking the class from the last
   character *inside* the box instead is what pushed every Chinese TOC title
   one `CJKecglue` to the right of its English counterpart.
   A run of dashes or ellipses is joined without glue, so justification cannot
   pull a two-em dash apart.  A punctuation mark takes no `CJKecglue` advance
   on either side: its own advance carries the spacing, and the extra third of
   an em is what made every `function` box of the Chinese manual overflow
   before the rule existed.  A zero-width glue stays at that boundary, so it
   is still a break opportunity and the kinsoku penalty can forbid it
   (`boundary01`).
3. `apply_fixed_widths` — give punctuation the advance the style asks for, by
   inserting a penalty and a kern after the mark. The ink is moved by class:
   an opening mark by the whole amount, a middle mark by half, a closing mark
   not at all. A dash or an ellipsis keeps its advance.
4. `apply_kinsoku` — insert a `\penalty 10000` at a break point the
   line-breaking prohibitions forbid.
5. `apply_check_single` — raise the penalty at the last two break points of a
   paragraph, so a single character cannot end up alone on the last line.

`post_linebreak_filter` runs `hang_punctuation` on the packed lines: it shifts
the ink of a mark at the start or the end of a line (hanging punctuation),
and with `PunctBoundWidth` it shifts a line-final mark so that only the given
advance stays inside the line.
Only `xoffset` changes, never a width, so justification is untouched.

The shift is not character protrusion, because the engine does not move the
ink at the end of a line: `\protrudechars` with `\rpcode` makes
`\rightmarginkern` report the amount (10pt for a right code of 1000 at 10pt)
while the glyph in the output keeps its position, in a short line, an overfull
line, and an exactly fitting one. `\lpcode` does move the line — the same
measurement shifts the first glyph by one em — and that is what the visible
part of `microtype`'s protrusion on a Latin line is. Hence `xoffset` here, and
`hang01` pins the numbers.

`pre_mlist_to_hlist_filter` runs `rewrite_math`, which points the math
character noads of a CJK character at a math family of its own; the family's
three style fonts are filled from the CJK family at the text, script, and
scriptscript size (0.7 and 0.5 of the text size), so a CJK character in a
superscript or a fraction takes the size of that math style. The family
number is allocated per CJK family name from 240--255 and travels in the
`math_font` attribute, which keeps `\setCJKmathfont` local to a group.
The math parameters stay those of the document's math font, because the CJK
font has no `MathConstants` table.

### Attributes

Ten attributes carry the per-node state; all are read through
`node.has_attribute`/`has_attribute`:

| attribute | meaning |
| --- | --- |
| `font` | font identifier of the CJK family that applies |
| `math_font` | the CJK math font identifier |
| `punct_font` | font identifier for punctuation (`PunctFamily`) |
| `cjk_space` | whether a source space inside CJK text is kept |
| `xecglue` | whether the CJK/Latin glue is suppressed at this space |
| `inserted` | marks the nodes LuaCJK created, so they are not examined twice |
| `disabled` | `\LuaCJKdisable` state |
| `nobreak` | `\LuaCJKnobreak` and `\LuaCJKVerbAddon` state |
| `settings` | number of the option snapshot that applies to this node |
| `LuaCJKfntef/settings` | number of the decoration settings entry |

### The settings snapshot

Every option used to be read from a TeX register at the moment the paragraph
was broken, which silently lost a setting whose group had closed before
`\par`, and made `{\small ...}` use the glue of the outer size. Now
`\@@_settings_push:` (called at the end of `\LuaCJKsetup` and after every
`\selectfont`) sends the current options to `LuaCJK.new_settings`, which
dedupes them by a signature string, stores the entry, and records its number in
the `settings` attribute. Lua reads `settings_of(node)` and never the TeX side.
Adding an option means touching all five places listed in `AGENTS.md`.

Two kernel hooks drive the push, both labeled `LuaCJK`:
`\hook_gput_code:nnn { selectfont }` fires while the size is being selected,
and `\hook_gput_code:nnn { cmd / selectfont / after }` repeats the push once
`\baselineskip` has settled, so the glue belongs to the new size; the guard
inside `\@@_update_font:` keeps the temporary font selections from pushing
twice. `cmd / rmfamily / after`, `cmd / sffamily / after`, and
`cmd / ttfamily / after` switch the family in the same way.

The snapshot is also where state that used to be a Lua global now lives, so a
group cannot leak it: `AutoFallBack` and the list of canceled sub-blocks are
fields of the entry, resolved per node, rather than flags on the module. When
a setting is described as "for the rest of the group", it belongs here; only
the character sets, the fake bold factors, and the load-time keys stay global.

`CJKglue` and `CJKecglue` keep their registers, but the defaults
(`0pt plus 0.08\baselineskip` and `0.3333em plus 0.1667em minus 0.1111em`)
are recomputed at each font selection unless the document set them; a document
value is used as written. That is what the `ccglue_touched` flags are for.

### The punctuation model

Every mark gets a group from `PUNCT_CLASS`: `open`, `close`, `middle`, `dash`,
`ellipsis`. Four character sets are editable at run time
(`M.charsets`): `kaiming` (marks that stay full width in the `kaiming` style),
`middle`, `long` (never compressed against each other), and `nobreak` (never
separated by a line break).
A style (`M.punct_styles`) is a table of six optional fields:

| field | effect |
| --- | --- |
| `compress_adjacent`, `ratio` | shorten the mark before another one by `ratio` of its width |
| `keep_open_close` | do not compress an opening against a closing mark |
| `fixed_ratio`, `fixed_full` | give every mark `fixed_ratio` of the em, except the `kaiming` set |
| `hanging` | shift line-initial and line-final marks by half an em |

The prohibitions in `forbids_break` are the ones that matter for correctness:
a closing or middle mark may not start a line, an opening mark may not end one,
and a run of `nobreak` long marks is one unit. `AllowBreakBetweenPuncts` and
`PunctKinsoku` gate these, but an explicit `nobreak` attribute bypasses both.
`CJLineBreak = strict` adds one rule of its own, from the Unicode
`Line_Break = CJ` set: those characters may not start a line. The set is read
from `LineBreak.txt` on the first use of the key, so the default pays nothing
for it; the key is independent of `PunctKinsoku`.

A mark is spaced by its own advance alone: at a boundary between a mark and
Latin text the spacing pass inserts a glue of zero width, so the mark's ink
starts where its advance starts; the node stays a break opportunity, which the
kinsoku penalty can then forbid, because the style's compression and hanging
are the only means by which the model moves a mark's ink.  A character that
`LatinPunct` treats as Latin (the quotation marks, the middle dot, the
ellipses) is not a CJK mark and keeps the glue.

### Rule decorations adjust `lua-ul`

`LuaCJKfntef` builds on `lua-ul`, which represents a decoration as a leaders
glue of width *w* followed by a glue of width *-w* that gives the space back.
`LuaCJKfntef.lua` finds that pair in `hpack_filter` and
`pre_append_to_vlist_filter`, and replaces the leaders by a sequence of kerns
and shorter leaders whose total is still *w*; the text therefore does not move
while the rule is inset (`subtract`) or left out over punctuation (`skip`).
The settings of one call live in `LuaCJKfntef.settings`, numbered by the
decoration attribute, so two decorations in one paragraph keep their own
settings.

A colored rule cannot use `\color`, which emits whatsits in front of
`\leaders`; it goes through `luacolor`'s attribute coloring
(`\luaul_set_color:n` plus `\luaul_apply_color:`),
which is why `format` takes a color name rather than code.

The `depth` key places the rule below the baseline. `boxdepth`, which used to
cap how much a rule added to the box, is gone: it was a workaround for the
drawn patterns growing the line, and on a rule it removed the rule itself.

### Drawn decorations stay out of the metrics

The wave, the emphasis dots, and the xout slash are drawings rather than
leaders of a rule. Each is built at use time inside
`\l_@@_fntef_pattern_box`, and the box is then set to zero height and depth, so
the pattern reaches the page as a PDF literal without entering the dimensions
of the line. That is why a decorated line keeps the leading of a plain one.

Two properties of `l3draw` shape the code. Its box is the bounding box of the
*stroked* path, one stroke width wider than the path, so a tiled pattern is
wrapped in `\hbox to <period>` with `\hss` on both sides and the period stays
exact instead of leaving a stroke-wide gap. It also places the drawing by the
bottom of that box, which lifts a path that goes below the baseline, so the
xout slash is lowered again by the part below the baseline plus half the
stroke. The `symbol` variants of `\CJKunderdot` and `\CJKunderwave`, and
`\CJKunderanysymbol`, follow one placement rule: one symbol per em, centered in
the cell, its top a given distance under the baseline.

### The ctex adapter

`ctex` inputs an engine file named `ctex-engine-<name>.def`, where `<name>` is
the detected engine unless the `engine` option names another, so LuaCJK
ships `ctex-engine-luacjk.def` and the document selects it with
`engine = luacjk`. The file implements the `ctex` interface
(`\ctex_add_to_selectfont:n`, `\ccwd`, `\CTEX@alchar`, `\ctex_set_jfm:n`, the
`kanjiskip`/`xkanjiskip` keys) on top of LuaCJK. `ctex` keeps its own copies of
the two glues so it can tell whether the document changed them; the engine file
keeps the copies in step and sets the `*_touched` flags, otherwise the next
`\selectfont` would restore the default and undo the user's `kanjiskip`.
The file also refuses `CJKfntef`, which `ctex`'s own LuaTeX backend bans
because it loads the legacy `CJK` package over the family interface: the check
runs when the engine file is read (`ver@CJKfntef.sty`) and again on the
`package/CJKfntef/before` hook, and the message names `LuaCJKfntef`.

The proof that the backend was actually taken over is the absence of
`luatexja` in every log, not a marker line: the option can be lost while
LuaCJK is still loaded from somewhere else. `ctex01.lvt` passes the option to
`ctexart`, so `l3build check` exercises the public route; the subset script
cannot pass it that way, because the `ctex` test tree brings its own
`ctexopts.cfg` that selects a fontset, so the script appends
`\keys_set:nn { ctex / option } { engine = luacjk }` to that file and both
settings apply. `ctex02.lvt` covers the `CJKfntef` refusal by overriding
`\msg_critical:nn` and ending the run.

### The manual's two languages

The user part of the manual (the `documentation` environment) is written
twice: Simplified Chinese first, English second, with the same block sequence
and the same markup; only the prose and the section titles are translated, and
every edit to one part is an edit to the other in the same task.  The
Implementation part is English only.  `scripts/check-bilingual.lua`, run by
`scripts/check-docs.sh`, compares the ordered structure (environment nesting,
the documented objects, the section levels, the list items) and the multiset of
interface references, so a change to one part alone fails the build.

`docext` restarts the `section` counter before every `documentation`
environment (the `env / documentation / before` hook), and the Chinese part
ends with an explicit `\setcounter{section}{0}`, so the two parts both number
from one.  The repeated numbers would also repeat the l3doc labels
(`doc/function//<name>`) and the PDF destinations (`section.1`): LaTeX then
warns `multiply defined` and the PDF backend drops the second target, so the
English TOC entries would jump into the Chinese part.  The manual therefore
tags each part: a `\LuaCJKdoclang{zh|en}` call sets a token that is a component
of `\theHpart` (whence `\theHsection` and `\theHsubsection`) and, through the
driver's redefinition of l3doc's `\__codedoc_get_hyper_target:nN`, of every
`doc/function/…` label.  The section anchors become `section.zh.1` /
`section.en.1`, the appendix stays `appendix.A`, and the index merges the two
pages of a documented name into one entry, because the index key is the name
alone.

The Chinese prose is set by LuaCJK itself: the driver's Noto Serif CJK SC gives
it its CJK font (with LXGW WenKai GB Lite as the CJK italic and the kai
family, Noto Sans CJK SC as the hei family, and Zhuque Fangsong as the
monospaced and fangsong face), full-width punctuation is CJK punctuation and
is compressed and hung by the punctuation passes.  The manual is a `ctex`
document, though: its driver loads `ctex` with `engine = luacjk` and
`linespread = 1`, so the glue defaults come from the engine file — the
CJK–Latin gap is `ctex`'s `.25em plus 1pt minus 1pt` and `xCJKecglue` is on,
not LuaCJK's own `.3333em` default.  Line breaking in the prose therefore
differs from a plain LuaCJK document, which is expected and must not be
"fixed" by resetting the glue.  `LatinPunct` stays on, so the ASCII quotes and
apostrophes inside code spans remain Latin.

The demos are executed in the manual, so a global command used in one changes
the rest of the document: `\setCJKmainfont` re-registers the family named by
`\CJKrmdefault`, and `AutoFakeBold` and `AutoFakeSlant` are global by design —
and they act when a family is registered, so `\LuaCJKdocsetup` clears them
before it sets the fonts again.  The `env/codemo/after` hook runs that command
after every demo, so the `\begingroup` around a `codemo` contains only local
settings.

## Current work

Implemented: font family layer with fake bold and slant, fallback fonts
and sub-blocks, `\CJKglue`/`\CJKecglue`/`xCJKecglue`/`CJKspace` with per-node
settings, six punctuation styles plus the character-set and style editing keys,
punctuation hanging and bound width, `CheckSingle`, `CJLineBreak`, `CJKmath`,
`\LuaCJKnobreak`, `\LuaCJKVerbAddon`, `\LuaCJKShipoutHook`, `LocalConfig`,
`LoadFandol`, eight decorations in `LuaCJKfntef` with twelve options, and
`LuaCJK-listings`.

Two inputs are handled before the passes: the zero-width format characters and
the variation selectors are given category code 9 at load time, so they neither
take glue nor split a CJK run.

Deliberately absent, with the reason recorded in the manual: `PoZheHaoLigature`
(the CJK font is applied after the text was shaped with the Latin font, so its
ligatures cannot be asked for), `RubberPunctSkip` (the advance is a fixed kern,
which is not a break opportunity and takes no part in justification),
`CheckFullRight` (the node list no longer shows the following control
sequence — use `\LuaCJKnobreak`), and `ulem`'s option list (`LuaCJKfntef` builds
on `lua-ul`). Picking a backend inside `ctex` is now a public option
(`engine`), so nothing here depends on the `ctex` maintainers' choice.

## Conventions

- Lengths on the Lua side are integers in scaled points; dimensions cross the
  boundary through `\dim_to_decimal_in_sp:n`.
- Code-point ranges cross the boundary as a Lua list of `{first, last}` pairs,
  built from the hexadecimal spelling (`"4E00 -> "9FFF`) in TeX.
- Glue crosses as a spec table `{width, stretch, shrink}`; `make_glue` and
  `set_glue` take that table, not a register name.
- A character class or punctuation override in `M.class_override` /
  `M.punct_override` always wins over `LatinPunct` and the built-in tables.
- `\LuaCJKsetwidth`, `\LuaCJKsetkern`, the four punctuation-set keys, and the
  `Declare*` commands are global by design; the manual says so at each of them.
- The manual is English; the package's user-facing prose keeps the same
  terminology as the code (`CJKglue`, `PunctStyle`, `subtract`) rather than
  inventing translations.
- Lua code declares its functions with `local function` and publishes only through `M`; no other
  name reaches the global environment except the module table that `LuaCJK.lua` creates.
- Inside a module a local is `snake_case` and a module-level constant is `UPPER_CASE`
  (`PUNCT_CLASS`, `DEFAULT_SETTINGS`, `M.punct_styles`).
- The code carries no narration. Each pass is introduced by prose in the dtx
  between `\end{macrocode}` and `\begin{macrocode}`; a Lua comment survives
  only when it explains a single expression. The three module headers are
  DocStrip preambles declared in `LuaCJK.ins`, in Lua comment syntax, so the
  generated files are valid Lua from the first line.

## Workflows and validation

The commands are in `AGENTS.md`. For this skill the points that matter are:

```bash
l3build check                       # 46 tests, must print "All checks passed"
l3build save <name>                 # only after inspecting why the baseline moved
bash scripts/ctex-subset.sh         # 21/21, and no log may mention luatexja
bash scripts/check-docs.sh          # guides, and the two documentation languages
```

When a change touches a pass, add a test that inspects nodes rather than
guessing from widths alone: walk `tex.box[0].head` and report the glue, kern,
and penalty nodes, then assert the numbers in the `.tlg`.
Existing examples are `decoration01` (the leaders pair), `settingsscope01`
(a group that closes before `\par`), `nobreak01`/`nobreak02` (penalties),
`listings01` (glyph order inside a listing), `ctex01`, the class test that
shows the engine file is reached through `engine = luacjk`, and `ctex02`,
which traps the `CJKfntef` refusal by overriding `\msg_critical:nn`.
