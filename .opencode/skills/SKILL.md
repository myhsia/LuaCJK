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
   The fallback list is resolved on the TeX side at each font selection, in
   the series, shape, and size in force, and is keyed by the identifier of
   the main font: a bold or a scaled main font has an identifier of its own,
   so one list per family would cover only the context it was declared in.
   `\g_@@_fallback_pushed_prop` records, per identifier, the family whose
   list is installed, so a selection that resolves to a known identifier
   costs one property lookup rather than another `\lua_now:e`.
   A glyph that changes font takes that font's `Baseline` with it:
   `copy_glyph` adds `M.yoffset[fid]` (scaled points) to the `yoffset` it
   copies.  Applying it only where the font changes is also what makes it
   idempotent, since the passes run twice and a glyph already in its font is
   not copied again.  The offset is recorded per font identifier, so two
   families that supply the same font share the last value they declared.
2. `spacing` — retime the source space between CJK characters to
   `CJKglue`, and insert `CJKglue`/`CJKecglue` at every boundary between two
   classes of character.  Dropping the space must not drop the boundary with
   it: line breaking happens before the `hpack_filter` pass that would add the
   glue, so a freed space leaves two characters that can neither be broken
   between nor stretched apart (`boundary03`).
   A space that a text font command moved across the italic correction is put
   back into the source-space class before the walk: `\textbf` and its siblings
   save the skip in front of them, `\unskip` it, apply the italic correction and
   reinsert it with `\hskip`, so the glue keeps the dimensions of the space but
   carries the subtype of a skip the document wrote (`boundary03`).
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
4. `hang_bounds` — insert the hang of a mark into the measure, as a zero-size
   rule of negative width beside the break glue (`hang01`). Only the
   `pre_linebreak_filter` path runs it: a box packed by `hpack_filter` cannot
   break a line, and a line box that is packed again would take the pair twice.
5. `apply_kinsoku` — insert a `\penalty 10000` at a break point the
   line-breaking prohibitions forbid. It reads a box at the edge that faces the
   break (`first_punct`/`last_punct`), so a mark inside an `\mbox` takes part.
   A discretionary that is already in the list states the value of its own
   break, so there the pass sets the node's penalty field instead of inserting
   a penalty in front of it.
6. `apply_check_single` — raise the penalty at the last two break points of a
   paragraph, so a single character cannot end up alone on the last line.

`post_linebreak_filter` is not used: the hang of a line-final mark is part of
the measure (see "The punctuation model"), so nothing has to be adjusted after
the lines are packed.

The `hyphenate` callback is the one that runs *inside* the line breaker:
`\TeX` inserts the hyphens of a word there, after `pre_linebreak_filter` has
already placed the prohibitions, so `M.hyphenate` hyphenates through
`lang.hyphenate` and then sets the penalty of each discretionary it created to
10000 when the letters on either side of it carry the `nobreak` attribute.
`disc.penalty` is the break value the line breaker reads, which is why the
prohibition is a field rather than a node: a penalty in front of a
discretionary forbids only an empty pre-break, and a `\-` would survive it.
Nothing else about the callback differs from the default, and a doubled
`lang.hyphenate` call leaves the list unchanged, so it composes with a
callback another package registers.

`pre_mlist_to_hlist_filter` runs `rewrite_math`, which points the math
character noads of a CJK character at a math family of its own; the family's
three style fonts are filled from the CJK family at the text, script, and
scriptscript size (0.7 and 0.5 of the text size), so a CJK character in a
superscript or a fraction takes the size of that math style. The face is the
one of the math version — `\bfdefault` in `bold`, `\mddefault` in the others,
always the upright shape — and `\@@_math_version_refresh:` re-registers the
family from `\every@math@size`, because `\mathversion` cannot reach a family
number it does not know; a group that asks for `\boldmath` therefore gets the
bold face and the group end restores the previous one. The family
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
| `nobreak` | `\LuaCJKnobreak` and `\LuaCJKVerbAddon` state: a break at glue, kern, or discretionary that touches a node carrying it is forbidden |
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
`cmd / ttfamily / after` switch the family in the same way, and
`cmd / normalfont / after` resets it to `\CJKfamilydefault`, which follows
`\CJKrmdefault` until the document gives it a value.  That reset passes an
unregistered name over in silence, because `\normalfont` also runs when the
document starts, before any family need exist.

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
| `hang` | let a line-final or line-initial mark stand in the margin by half its advance |

Every style but `plain` sets `hang`, which is what `hangmobanjiao` used to
mean on its own: the mark keeps its full advance and the line ends flush.

The prohibitions in `forbids_break` are the ones that matter for correctness:
a closing or middle mark may not start a line, an opening mark may not end one,
a run of `nobreak` long marks is one unit, and two adjacent marks are not
separated. `PunctKinsoku` gates all four; `AllowBreakBetweenPuncts` lifts the
last alone, because the other three are rules of the script, and the adjacent
rule leaves a dash or an ellipsis out, since a run of them is governed by the
`nobreak` set. An explicit `nobreak` attribute bypasses both keys. The pass
reads a box at the edge that faces the break, so a mark inside a box is seen;
`first_punct` and `last_punct` return the group, the glyph that carries it, and
whether a character was found at all.
`CJLineBreak = strict` adds one rule of its own, from the Unicode
`Line_Break = CJ` set: those characters may not start a line. The set is read
from `LineBreak.txt` on the first use of the key, so the default pays nothing
for it; the key is independent of `PunctKinsoku`.

A mark is spaced by its own advance alone: at a boundary between a mark and
Latin text the spacing pass inserts a glue of zero width, so the mark's ink
starts where its advance starts; the node stays a break opportunity, which the
kinsoku penalty can then forbid.  A character that
`LatinPunct` treats as Latin (the quotation marks, the middle dot, the
ellipses) is not a CJK mark and keeps the glue.

The hang of a line-edge mark is part of the measure, not a shift applied after
the fact: beside every break glue that a closing or middle mark ends, and
before every one an opening mark starts, `hang_bounds` puts a zero-size rule of
negative width and adds the same width to the glue. Inside a line the two
cancel; at a break the glue is discarded and the rule alone shortens the line,
so the mark's ink stands in the margin and the line can hold a mark its natural
width would refuse. A kern would not do, because a kern after a character is a
break opportunity of its own and would take a kinsoku penalty; character
protrusion would not either, because `\rpcode` leaves the ink where it was. The
amount is the blank the mark's font carries, read from the outline by
`mark_blank` (`CFF` charstring or `glyf` header, cached per file and glyph, the
file never held whole), or half of the advance the style gives it when the file
cannot be read; `PunctBoundWidth` replaces it by the part that stays inside.
LuaTeX has no `\XeTeXglyphbounds`, which is why xeCJK's one-line query is a
small font reader here. `hang01` pins the pair and the fit, `boundw01` the
amount, and `punct01` the compressed style.

Suspension does not take that break opportunity away.  `Verb` stops the spacing
on both sides of a suspended run, but a mark next to it keeps its zero-width
glue: the glue moves no ink, and the mark belongs to the running text rather
than to the run.  An opening mark is the exception, because a break after it is
prohibited and the pass skips a break that involves suspended material, so the
prohibition cannot be applied across it; `verb02` pins both cases, together with
the line that ends at the mark.

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

A type is built once and reused, and it keeps the color it was built with:
`lua-ul` copies the attributes of the built box onto every leader, so the cache
key of a rule or a symbol decoration carries the color — `format` when it is
set, otherwise the value of `luacolor`'s attribute, which is the color of the
surrounding text.  Without that, a second call inherits the color of the first.
The name of the type already carries a counter, which is why the `lua-ul`
context can be the constant `LuaCJKfntef`; a context that expands again when the
type is used would rebuild it with whatever color is current at that moment.
The single rule and the strike-out carry their own color in the same way, in
`\@@_fntef_formatted_underline:` and `\@@_fntef_use_sout:`.

Every decoration parses one key set: a pair goes to the keys, and a bare item
that names no key is a color and means `format`, so `[red]` and `[subtract]`
both work. A key that a command does not use is accepted and ignored, and
`textformat` and `hidden` go through one body helper, so they behave the same
in all eight commands.

A CJK em box is one em square, so a highlight that covers a character is
`1em` wide and `1em` high, with the box bottom at the em descent below the
baseline. `\LuaCJKemdescent` is that descent: `LuaCJKfntef.em_descent` reads
`descent` and `units_per_em` from the font file, caches them per file name
(one parse serves every size), scales by the font size, and falls back to
`.12em`. The same value places a symbol, so a gap of `0pt` leaves the same
space below the character as the side bearings leave beside it.

The font it measures is the one the `font` attribute carries, not
`\g_@@_fontid_int`: the integer is global state that
`{\fontsize{…}\selectfont …}` leaves at the size it last saw, while the
attribute belongs to the group and returns with it. Every quantity that
describes "the font in force here" is read the same way.

Leaders repeat the box and only whole copies fit, so the last fraction of a
span stays empty. With a one-point object that shortened a highlight at the
right end by up to a point whenever the em was not a whole number of points,
which is the case at `\small` in an 11pt document. A leader box that holds
nothing but one rule is therefore replaced by a single rule node of the
segment width, with the height and depth shifted by the box's own
translation; the replacement keeps the rule's attributes, so the color
survives. A box that holds a pattern (the symbols) keeps the leaders.

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
the cell, its top a given distance under the *bottom of the em box*. The
measured descent is part of the cached type key, so a font change does not
reuse a stale placement.

### The listings patch

`listings` typesets a character it does not know at the moment it reads it, so
CJK characters arrive in front of the surrounding Latin text.
`LuaCJK-listings` sets the CJK ranges to category code 13 while a listing's
character table is built, which sends them through `listings`' token mechanism
instead; each character counts as two columns, and `\LuaCJKdisable` is applied
in `OutputBox` so the spacing adjustments stay out of the listing. The active
characters are defined once through the `lccode` of two helper characters and
`\lowercase`, which leaves the body token at category code 12, so it can be
stored in a token list and typeset later. `\lstinline` reads its argument with
changed category codes, so the patch is limited to the block environments.

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

### Tagged PDF and copy safety

Tagging is a property of the document: the package tests for `\tag_*` and
`\tagpdfpara*` with `\cs_if_exist:NT` and does nothing when tagging is off.
It never loads `tagpdf`. The manual is itself tagged: its driver declares
`\DocumentMetadata{tagging=on,pdfversion=1.7,lang=zh-CN}` and loads
`latex-lab-testphase-l3doc`; `\LuaCJKdoclang{zh|en}` also sets `text/lang`
for the structure elements.

The ink of a decoration is not text. A symbol is wrapped in an `ActualText`
sequence whose replacement is `U+200B`, so a reader drops it from the text it
extracts and selects; `selectable = true` keeps it as text. The wrapper is a
`pdf_literal` inside the leader box, not a font change: a cloned font used in
a `\leaders` box aborts LuaTeX at shipout.

`\CJKfilltwosides` tags by mode. In vertical mode the vbox becomes a
`text-block` structure; in horizontal mode its MC joins the surrounding
paragraph. A `text-block` inside a paragraph is invalid (`P --> P`), and the
automatic paragraph hooks stay off around the vbox.

The reader's selection height comes from the font's `hhea` ascent and descent,
not from the em box. For Noto Serif CJK SC that is 1.437em, so the selection
is taller than the 1em square even when the highlight is right. Tagging does
not change it; the manual documents the limitation.

## Current work

Implemented: font family layer with fake bold and slant, fallback fonts,
sub-blocks, and a per-font baseline shift,
`\CJKglue`/`\CJKecglue`/`xCJKecglue`/`CJKspace` with per-node settings,
six punctuation styles plus the character-set and style editing keys,
punctuation hanging and bound width, `CheckSingle`, `CJLineBreak`, `CJKmath`,
`\LuaCJKnobreak`, `\LuaCJKVerbAddon`, `\LuaCJKShipoutHook`, `LocalConfig`,
`LoadFandol`, eight decorations in `LuaCJKfntef` with thirteen options, tagged
PDF output, and `LuaCJK-listings`.

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
- The user-facing prose keeps the terminology of the code (`CJKglue`,
  `PunctStyle`, `subtract`) rather than inventing translations, in both
  languages of the manual (see "The manual's two languages").
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
l3build check                       # 55 tests, must print "All checks passed"
l3build save <name>                 # only after inspecting why the baseline moved
bash scripts/ctex-subset.sh         # 21/21, and no log may mention luatexja
bash scripts/check-docs.sh          # guides, and the two documentation languages
```

When a change touches a pass, add a test that inspects nodes rather than
guessing from widths alone: walk `tex.box[0].head` and report the glue, kern,
and penalty nodes, then assert the numbers in the `.tlg`.
Existing examples are `decoration01` (the leaders pair), `selectable01` (the
`ActualText` wrapper and the `selectable` key), `tagging01` (tagged
decorations and both branches of `CJKfilltwosides`), `settingsscope01`
(a group that closes before `\par`), `nobreak01`/`nobreak02` (penalties),
`nobreak03` (the penalty field of a discretionary),
`listings01` (glyph order inside a listing), `ctex01`, the class test that
shows the engine file is reached through `engine = luacjk`, and `ctex02`,
which traps the `CJKfntef` refusal by overriding `\msg_critical:nn`.
