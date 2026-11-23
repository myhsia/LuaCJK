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
`hpack_filter` (the source is `local function process`), except the font
substitution, which runs in luaotfload's `pre_shaping_filter`, before either:

0. `pre_shaping` — set each CJK glyph in the font family recorded on it
   (`\g_@@_font_attr`), then in the punctuation family or a sub-block font
   if one applies, then in a fallback font when the target lacks the glyph
   (the chain is `target_font`); and let a character that attaches to the one
   in front of it — a joiner or a variation selector — follow that font,
   marked with the `attached` attribute.  It runs before shaping because
   shaping is what attaches a combining mark to its base and what a joiner
   and a selector act on: a glyph copied into another font afterwards keeps
   the form of the font it was shaped in, which is why `か` + U+3099 used to
   come out as two glyphs while the precomposed `が` was one (`shaping01`).
   The price is that the CJK font's own features now apply: its ligatures
   (Noto Serif CJK joins `——` into one two-em dash), `locl`, and variation
   sequences.
   The fallback list is resolved on the TeX side at each font selection, in
   the series, shape, and size in force, and is keyed by the identifier of
   the main font: a bold or a scaled main font has an identifier of its own,
   so one list per family would cover only the context it was declared in.
   `\g_@@_fallback_pushed_prop` records, per identifier, the family whose
   list is installed, so a selection that resolves to a known identifier
   costs one property lookup rather than another `\lua_now:e`.
   A glyph that changes font takes that font's `Baseline` with it: the pass
   adds the offset (scaled points) to the glyph's `yoffset`.  Applying it only
   where the font changes is what makes the pass idempotent, since it runs on
   the paragraph and again on each line packed from it.  The offset comes from
   the step `target_font` took: the text reads the `shift` attribute and a mark
   the `punct_shift` one, which `\@@_update_font:` fills at every font
   selection with the value of the family in force, evaluated at the size in
   force.  Being attributes, they follow the group, so a family selected inside
   a group moves only that group's characters, and two declarations that name
   the same font keep their own offsets in one paragraph; a table keyed by font
   identifier could do neither, because every declaration that supplies the
   font shares the identifier.  A fallback font is the exception: it is chosen
   here, when the text is shaped, and only its identifier says which one
   applies, so `M.yoffset[fid]` carries its offset, filled by
   `\@@_push_shift:nnn` at each font selection and handed over again only when
   it changed (`baselineshift01`).
   A luaotfload without `pre_shaping_filter` keeps the package's previous
   behavior: `rewrite_fonts` copies each shaped glyph into its font in
   `process` instead, `copy_glyph` adds the `Baseline` there, and every
   zero-width character is removed at the input.  No test reaches that path,
   because the callback type cannot be taken out of a live callback list; a
   probe that edits the flag in an unpacked copy is how it is checked by hand.
1. `drop_orphans` — remove what shaping left of the characters that must not
   reach the spacing pass: a glyph carrying the `attached` attribute, with the
   kern that cancels the advance of its placeholder, and the box a CJK font
   draws for a character it does not have.  The second rule consults
   `missing_chars`, filled by `pre_shaping`, so a document that declares no
   CJK font at all still shows the box (`loadfandol03`) while a character the
   CJK font lacks takes no advance (`shaping01`).  Dropping the joiner before
   the walk is what keeps `中` + U+200D + `文` at `4E2D glue 6587`
   (`zwchars01`).
2. `spacing` — retime the source space between CJK characters to
   `CJKglue`, and insert `CJKglue`/`CJKecglue` at every boundary between two
   classes of character.  Dropping the space must not drop the boundary with
   it: line breaking happens before the `hpack_filter` pass that would add the
   glue, so a freed space leaves two characters that can neither be broken
   between nor stretched apart (`boundary03`).
   A space the document wrote with `\ ` or `~` is not a source space, and the
   node list does not say so: the two reach the pass as the same `spaceskip`
   glue with the same dimensions.  The TeX side therefore marks the one it
   wrote itself with the `explicit_space` attribute, and the pass leaves a
   marked glue alone, so the space keeps the advance of the font it came from
   instead of becoming the inter-character glue (`boundary03`).  A whatsit,
   mark, insertion, or adjustment between that glue and the next character is
   passed over, so the color change `\textcolor` inserts does not hide the
   space and no second glue joins it; a penalty ends the search because it has
   its own rule.
   A space that a text font command moved across the italic correction is put
   back into the source-space class before the walk: `\textbf` and its siblings
   save the skip in front of them, `\unskip` it, apply the italic correction and
   reinsert it with `\hskip`, so the glue keeps the dimensions of the space but
   carries the subtype of a skip the document wrote (`boundary03`).  Only a glue
   of normal order is read that way — a space never has a stretch or shrink
   order — so an `\hfill` or `\hfil` that stands after the same italic
   correction keeps its own subtype instead of becoming the inter-character
   glue and taking the fill of the line with it (`boundary01`).
   A box is an atom, and the class at its edge is the class of the text
   nearest that edge: a kern, a spacing glue, or a rule inside the box does
   not hide that text, so the boundary glue is added by the class of the text
   and not by a skip the document wrote inside the box (`boundary01`).  That
   holds for a vertical box as well, so the rule under `\underline`'s text does
   not hide it and `中\underline{ABC}文` takes the glue on both sides, like the
   run `\mbox` or `\CJKunderline` holds.  A
   filling glue is the exception: the text does not reach the edge of a box it
   stretches, so `\numberline`'s `\hfil` leaves the edge without a class and a
   Chinese TOC title stays aligned with its English counterpart.  A box that
   holds no text but has ink is a Latin atom, so `\mbox{\vrule}` takes the
   glue on both sides; a box that occupies no advance is passed over, so
   `\rlap`, `\llap` and `\clap` overlay the run instead of splitting it
   (`boundary01`).
   A box whose own baseline TeX has shifted is attached to the character in
   front of it: the run ends at it, so it takes no glue on either side and
   offers no break.  That is the box `\textsuperscript` and `\textsubscript`
   build, and the shift is the box's own field, so the outer box of a
   `\raisebox` or of a footnote mark keeps its boundary (`boundary04`).
   Each boundary reads the option snapshot of the CJK character it touches
   (`boundary_settings`), so the CJK/Latin glue is the CJK text's: a Latin run
   set with `\scriptsize` or `\large` keeps the `CJKecglue` of the surrounding
   text on both of its sides, where reading the previous node alone took the
   run's own size on its right (`settingsscope01`).
   A run of dashes or ellipses is joined without glue, so justification cannot
   pull a two-em dash apart.  A punctuation mark takes no `CJKecglue` advance
   on either side: its own advance carries the spacing, and the extra third of
   an em is what made every `function` box of the Chinese manual overflow
   before the rule existed.  A zero-width glue stays at that boundary, so it
   is still a break opportunity and the kinsoku penalty can forbid it
   (`boundary01`).
   Two adjacent marks are spaced by the blank between their ink (`pair_kern`):
   a length from `\LuaCJKsetkern` is that blank, so `0pt` makes the inks meet,
   and without one the style's ratio decides, never taking more than the right
   blank of the mark it compresses, so an em dash or a fullwidth percent sign
   keeps its ink.  The kern stands in front of the boundary glue, so the glue
   still offers the break and still carries the stretch.  A source space
   between two marks is retimed to that same glue and the blank rides in its
   width, so a line break in the source no longer spaces the two marks apart;
   because a break discards the glue, the compression leaves with it
   (`punct01`).
   A penalty that prohibits the break (`\penalty 10000`, `\nobreak`) does not
   end the run: the glue goes *after* it, where the prohibition still covers
   the break the glue offers, so `中文\nobreak ABC` keeps its `CJKecglue` and
   a source space in front of the penalty is converted with the penalty moved
   in front of it (`nobreak04`).  A lower penalty prices a break instead, and
   the glue would give that place a second break at no cost, so a priced
   penalty stays a barrier.  The character on each side is read from the
   visible node, not from the glue's predecessor, so a whatsit or a penalty
   between two marks does not hide them from the long-punct rule.
3. `apply_fixed_widths` — give punctuation the advance the style asks for, by
   inserting a penalty and a kern after the mark. A ratio style reads the
   advance and the place of the ink from the outline (`style_metrics`): the
   smaller blank stays on both sides and the rest of the outer blank is taken,
   so an opening mark moves left by what it loses, a closing mark keeps its
   ink, a middle mark is centred, and a mark whose ink nearly fills its
   advance (％, ＄, ￥) keeps the full width instead of losing part of the ink.
   A width the document sets with `\LuaCJKsetwidth` or `PunctWidth` is used as
   it stands, with the class moving the ink. A dash or an ellipsis keeps its
   advance. `hang_amount` measures inside `fixed_advance`, the same
   computation, so a widened mark hangs by the blank it really has. A mark that
   already carries the pair the pass inserted is passed over, because
   `hpack_filter` walks the same list again for every box that holds it
   (`punct01`, `punctgeom01`).
4. `hang_bounds` — insert the hang of a mark into the measure, as a zero-size
   rule of negative width beside the break glue (`hang01`), and at the two
   boundaries that carry no glue: in front of the opening mark that begins a
   paragraph, after its indentation (which arrives as an empty box of the width
   of `\parindent`) or after the label box of a list item, and after the penalty
   that holds a break the document forced. The label box is the box the list
   writes in front of the item's text and follows with a penalty of zero, which
   is how `head_lead` tells it from a box that carries text of the paragraph.
   Only the `pre_linebreak_filter` path runs it: a box packed by `hpack_filter`
   cannot break a line, and a line box that is packed again would take the pair
   twice.  The two hand-bracketed boundaries are left out when `\leftskip`
   carries a fill, which is how centered and flush-right text are set: the line
   then begins at the centering position, not at the edge of the measure, and
   the rule would shift the whole line instead of leaving the blank in a margin
   that is not there.  The hang at a break stays in every case, because the
   line breaker has already counted it when it decides that the mark fits, and
   there it is what keeps the ink of a line end on the right edge.  The last
   line of such a paragraph is bracketed by hand, because no break glue ends
   it: the bare rule goes behind the last mark, with no glue to widen, and only
   when `\leftskip` carries a fill, since otherwise the trailing fill absorbs
   the rule and the ink does not move (`hang01`).
5. `apply_kinsoku` — insert a `\penalty 10000` at a break point the
   line-breaking prohibitions forbid. It reads a box at the edge that faces the
   break (`first_punct`/`last_punct`), so a mark inside an `\mbox` takes part.
   A discretionary that is already in the list states the value of its own
   break, so there the pass sets the node's penalty field instead of inserting
   a penalty in front of it.
   The break points it reads are the glue the package inserted and the source
   spaces; a glue the document wrote is read as well when it carries the
   `nobreak` attribute, which is how a `\quad` or an `\hspace` inside
   `\LuaCJKnobreak` keeps its place on the line (`nobreak03`).
   A break is forbidden when the material on both sides of it carries the mark,
   or when a node the document wrote carries it; the glue and kerns the spacing
   pass inserts inherit the attributes of the character in front of them, so a
   mark there belongs to a decoration and not to the break, and the boundary
   between the argument and the text around it belongs to that text
   (`nobreak01`, `nobreak03`).
6. `apply_check_single` — raise the penalty at the last two break points of a
   paragraph, so a single character cannot end up alone on the last line.
   The scan back to the previous character passes over `transparent_node` —
   whatsit, mark, insertion, adjustment, penalty — and the kerns the package
   inserted, so a `\textcolor` between two characters no longer hides the
   break point; the penalty is spliced in front of the glue and left out when
   a penalty already stands there (`checksingle01`).

`post_linebreak_filter` is not used: the hang of a line-final mark is part of
the measure (see "The punctuation model"), so nothing has to be adjusted after
the lines are packed.

The `hyphenate` callback is the one that runs *inside* the line breaker:
`\TeX` inserts the hyphens of a word there, after `pre_linebreak_filter` has
already placed the prohibitions, so `M.hyphenate` hyphenates through
`lang.hyphenate` and then sets the penalty of each discretionary it created to
10000 when the letters on both sides of it carry the `nobreak` attribute.
A CJK character is a letter to `\TeX`, so it is also a word boundary here: the
callback hyphenates each run of non-CJK text between two CJK characters on its
own, which keeps a hyphenation point from standing between a CJK character and
the Latin word beside it and leaves the `CJKecglue` at that boundary in place
(`hyphen01`).
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
superscript or a fraction takes the size of that math style. The text size is
`\glb@currsize`, not `\f@size`: `\text` sets `\f@size` to the script size for
the branches of its `\mathchoice` that it discards, and a family built there
would keep that size. The face is the one of the math version — `\bfdefault`
in `bold`, `\mddefault` in the others, always the upright shape — and
`\@@_math_version_refresh:` re-registers the family from `\every@math@size`,
because `\mathversion` cannot reach a family number it does not know; a group
that asks for `\boldmath` therefore gets the bold face and the group end
restores the previous one. The family number is allocated per CJK family name
from 240--255 and travels in the `math_font` attribute, which keeps
`\setCJKmathfont` local to a group. The fallback fonts of the family are
registered as math families too; `M.math_fallback` holds, per family number, a
flat chain of (font to test, family to set) pairs with the family's own text
font first, and `rewrite_math` sets a character in the first font of the chain
that has it, gated by `AutoFallBack`. The math parameters stay those of the
document's math font, because the CJK font has no `MathConstants` table.

### Attributes

Fourteen attributes carry the per-node state; all are read through
`node.has_attribute`/`has_attribute`:

| attribute | meaning |
| --- | --- |
| `font` | font identifier of the CJK family that applies |
| `math_font` | the CJK math font identifier |
| `punct_font` | font identifier for punctuation (`PunctFamily`) |
| `shift` | the `Baseline` of the family in force, in scaled points, positive upwards |
| `punct_shift` | the `Baseline` of the family `PunctFamily` names, in scaled points |
| `cjk_space` | whether a source space inside CJK text is kept |
| `explicit_space` | the space is one the document wrote with `\ ` or `~`, not a source space |
| `xecglue` | whether the CJK/Latin glue is suppressed at this space |
| `inserted` | marks the nodes LuaCJK created, so they are not examined twice |
| `disabled` | `\LuaCJKdisable` state |
| `nobreak` | `\LuaCJKnobreak` and `\LuaCJKVerbAddon` state: a break whose two sides carry it is forbidden, and so is a break at a glue or kern the document wrote with it; a mark a node inherits from the character in front of it is a decoration's record and not a prohibition |
| `settings` | number of the option snapshot that applies to this node |
| `attached` | the character is a joiner or a variation selector, so `drop_orphans` removes what shaping left of it |
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
`\familydefault` — the matching one of `\CJKrmdefault`, `\CJKsfdefault`, and
`\CJKttdefault` — until the document gives it a value of its own.  That reset
passes an unregistered name over in silence, because `\normalfont` also runs
when the document starts, before any family need exist.

`\CJKfamily` and `\setCJKfamilyfont` expand the name they are given, so a
family is named by the macro that holds it — `\CJKfamily{\CJKsfdefault}`
selects what `\sffamily` selects — and both agree with the hooks and with
`\setCJKfallbackfamilyfont`, which expands the same way.  An undeclared name is
therefore reported by its expansion.  The lookup itself stays textual: the prop
key is the expanded name, not a canonical form of it.

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
`ellipsis`, `half-open`/`half-close` for the ASCII brackets, and `latin-close`
for the ASCII closing marks. Four character sets are editable at run time
(`M.charsets`): `kaiming` (marks that stay full width in the `kaiming` style),
`middle`, `long` (never compressed against each other), and `nobreak` (never
separated by a line break).
The groups are the lists of xeCJK: `OP` and `PR` are `open`; `CL`, `PO`, `EX`,
and `IS` are `close`; the hyphens (`301C`, `30A0`, `FF5E`) are `dash`; and `NS`
is read as `close` (`FF1A`, `FF1B`) or `middle` (`30FB`, `FF65`), because
`middle` means the ink is centred in the box and those two are not.
A mark is listed only when `CJK_RANGES` holds it as well, so the small-form and
vertical variants outside that table (`FE10`–`FE19`, `FE50`–`FE6A`, `2E3A`,
`16FE0`) keep no class; classing one is a `chars` change to both the range table
and the listings table.  The ASCII brackets are the one exception: `(`, `[`, and
`{` are `half-open` and `)`, `]`, and `}` are `half-close`, although they are
Latin glyphs outside `CJK_RANGES`.  They keep their own advance (a compression
style leaves them alone), do not hang, and take the CJK–Latin glue only in front
of an opening one, so a pair hugs the text between it; neither side of a pair
offers a break at all, because no glue stands there, and `PunctKinsoku` keeps a
half-width opening bracket out of the line end and a closing one out of the line
start wherever a break does exist (`punct02`).
The ASCII closing marks — `!`, `"`, `%`, `'`, `,`, `.`, `:`, `;`, `?` — are the
other exception and the group `latin-close`: a mark that ends an English phrase
even inside CJK text.  It takes the zero-width boundary glue of any mark beside
CJK and may not start a line (a break after it is allowed, unlike a bracket), and
`inert_mark` keeps it out of `pair_kern` and `fixed_width`, so no compression,
no hang, and no `PunctWidth` reaches a Latin period; `\LuaCJKDeclarePunctClass`
declares the group and `{none}` gives the character its word spacing back
(`latinpunct02`).
A style (`M.punct_styles`) is a table of six optional fields:

| field | effect |
| --- | --- |
| `compress_adjacent`, `ratio` | shorten the mark before another one by `ratio` of its width |
| `keep_open_close` | do not compress an opening against a closing mark |
| `fixed_ratio`, `fixed_full` | give every mark `fixed_ratio` of the em, except the `kaiming` set, and never less than the ink and its smaller blank |
| `hang` | let a line-final or line-initial mark stand in the margin by half its advance |

Every style but `plain` sets `hang`, which is what `hangmobanjiao` used to
mean on its own: the mark keeps its full advance and the line ends flush.

The prohibitions in `forbids_break` are the ones that matter for correctness:
a closing, middle, dash, or ellipsis mark may not start a line — a dash or an
ellipsis only as the first mark of a run, so the break between the marks of a
run stays the business of the `nobreak` set, and the group rule is clreq's
*strict* level and xeCJK's `FullRight`, though the groups are whole and U+2015
and U+FF0D take it too — an opening mark may not end one, a run of `nobreak`
long marks is one unit, and two adjacent marks are not separated.
`PunctKinsoku` gates all four; `AllowBreakBetweenPuncts` lifts the
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
width would refuse. The last line of a paragraph has no break glue to widen, so
there the rule goes in alone, and it is the trailing fill of a justified or
ragged-right line that absorbs it: only a line that starts at the centering
position, or at the right edge, moves its ink (`hang01`). A kern would not do,
because a kern after a character is a
break opportunity of its own and would take a kinsoku penalty; character
protrusion would not either, because `\rpcode` leaves the ink where it was. The
amount is the blank the mark's font carries, read from the outline by
`mark_blank` (`CFF` charstring or `glyf` header, cached per file and glyph, the
file never held whole), or half of the advance the style gives it when the file
cannot be read; `PunctBoundWidth` replaces it by the part that stays inside.
The box is taken at the extremum of a curve, not at its control points, because
a handle lies outside the ink the curve paints; the alternating curve operators
read their third point's abscissa from the operand that carries it, and the
four operators of the flex family draw the two curves they describe.  LuaTeX has
no `\XeTeXglyphbounds`, which is why xeCJK's one-line query is a small font
reader here; `fontloader` would be exact too, but `to_table` costs a second and
a hundred megabytes on a CJK collection.  `hang01` pins the pair and the fit,
`boundw01` the amount, and `punct01` the compressed style.

Suspension does not take that break opportunity away.  `Verb` stops the spacing
on both sides of a suspended run, but the zero-width glue stays at either edge:
it moves no ink, and a `\verb` beside a CJK character can end a line where the
`CJKecglue` would have been.  The mark prohibitions are applied when the glue is
inserted (`suspended_break`), because the kinsoku pass skips a break that
involves suspended material: no break follows an opening mark or precedes a
closing, middle, or long mark that begins a run, and two Latin words stay whole.
`verb02` pins the right and left edges, the closing mark, and the line that ends
at the mark.

`\LuaCJKVerbAddon` is the exception, and it has to be: the gap that makes one
CJK character two columns reaches the text only through the spacing pass, and
that pass leaves a suspended node alone, so an addon that only set `CJKglue`
would compute a gap nobody inserts.  The environment hooks suspend the material
before `formatcom` runs (`\FV@FormattingPrep` selects the font first), which is
why the default `Verb = true` silently undid the addon.  The command therefore
clears the attribute in its own group after reading it into
`\l_@@_verb_saved_disabled_int`, and `\LuaCJKOffVerbAddon` restores the value it
read; the state is read from the attribute register rather than tracked in a
second flag, so `\LuaCJKdisable` and the hooks stay the only writers.
Re-enabling is all-or-nothing, so the punctuation rules return with the spacing,
which is what `Verb = env+` does anyway; `verbaddon01` pins the mechanism and
`verbaddon02` the environment, measuring each fancyvrb line's natural width
where `\FancyVerbFormatLine` formats it, because the line box itself is
`\hbox to \linewidth`.

The same hook is why fancyvrb's *inline* commands are now wired to `Verb` at
all.  `\Verb` and `\UseVerb` never select `\verbatim@font` and are not
environments, so neither the font hook nor the environment list saw them, and
`\Verb` behaved as if `Verb = false` whatever the option said.  Its
`\FV@FormattingPrep` is shared by the inline commands and by every block, so
`\@@_fv_prep_hook:` is prepended to it and decides by
`\l_@@_verbatim_block_bool`: a block follows the environments (`true` only),
anything else follows `\verb` (`true` and `env`).  The flag is set by the block
side — the environment begin hooks and a group around `\FV@UseVerbatim`, which
serves `\UseVerbatim` and `\VerbatimInput` — because the inline side cannot mark
itself: a token written after `\Verb` is scanned into its text, since the
scanner reads to the end of the line, and wrapping `\FVC@Verb` closes the wrong
group, because it ends its own group from inside the `\mbox` it sets.  Both
attempts were measured and fail with a runaway argument and a brace imbalance
respectively.  The patch waits for `package/fancyvrb/after` and is also called
at load time, so either loading order works (`fancyvrb01`, `fancyvrb02`).

### Rule decorations adjust `lua-ul`

`LuaCJKfntef` builds on `lua-ul`, which represents a decoration as a leaders
glue of width *w* followed by a glue of width *-w* that gives the space back.
`LuaCJKfntef.lua` finds that pair in `hpack_filter` and
`pre_append_to_vlist_filter`, and replaces the leaders by a sequence of kerns
and shorter leaders whose widths, stretches, and shrinks still add up to *w*,
*st*, and *sh*: the text therefore does not move while the rule is inset
(`subtract`) or left out over punctuation (`skip`), and the line spaces as it
would with no decoration.  The stretch of the pair mirrors the text under it,
so each piece takes its share in proportion to its width and the last piece
takes the remainder.  A `kern` node has no `width` field in LuaTeX, so every
interval is measured through `node_width`, which reads `kern` for a kern.
The settings of one call live in `LuaCJKfntef.settings`, numbered by the
decoration attribute, so two decorations in one paragraph keep their own
settings.

A colored rule cannot use `\color`, which emits whatsits in front of
`\leaders`; it goes through `luacolor`'s attribute coloring
(`\luaul_set_color:n` plus `\luaul_apply_color:`),
which is why `format` takes a color name rather than code.

A type is built once and reused, and it keeps the color and the font size it
was built with: `lua-ul` copies the attributes of the built box onto every
leader, and it scans that box once per type, so the cache key of a rule or a
symbol decoration carries the color — the operations that
`\luaul_context_color:` holds after `\luaul_set_color:n` when `format` is set,
otherwise the value of `luacolor`'s attribute, which is the color of the
surrounding text — and the current font size, without which a pattern written
in `em` units keeps the size of the first call.  Without the color a second call
inherits the color of the first.  The key holds those resolved operations rather
than the name the document wrote, because `\colorlet` may redefine a name
between two calls.  The name of the type already carries a counter, which is why
the `lua-ul` context can be the constant `LuaCJKfntef`; a context that expands
again when the type is used would rebuild it with whatever color is current at
that moment.  The single rule and the strike-out carry their own color in the
same way, in `\@@_fntef_formatted_underline:` and `\@@_fntef_use_sout:`.

Every decoration parses one key set: a pair goes to the keys, and a bare item
that names no key is a color and means `format`, so `[red]` and `[subtract]`
both work. A key that a command does not use is accepted and ignored, and
`textformat` goes through one body helper, so it behaves the same in all eight
commands.

`hidden` is not a key of that helper: a `\phantom` is one unbreakable box, so a
hidden paragraph overflowed in a single line instead of breaking. It travels in
the settings snapshot like `skip` and `subtract`, and the pass replaces every
glyph of the span by a kern of the same width, with one rule of no width
carrying the height and the depth. The line breaking of a paragraph is decided
before the pass runs, so the hidden text breaks exactly like the visible one,
and no glyph of it reaches the PDF to be read or selected.

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
nothing but one rule is therefore given a rule of zero width, which `\leaders`
fills to the whole width of the glue: the rule covers the interval exactly, it
follows the glue when the line stretches, and it keeps the rule's attributes,
so the color survives. The height and depth are shifted by the box's own
translation.

A repeated box is not even placed from the left edge of its glue: `\leaders`
aligns the copies at the left edge of the enclosing box, and only a copy that
lies wholly inside the glue is drawn. A span that is not a whole number of
patterns therefore loses one at one end, which is what a wave showed whose span
ended in the middle of a stretched line, and a one-em symbol whose span begins
half a cell off that grid loses every copy, which is what a single indented
character showed.

The remainder cannot be spread either. `\xleaders` divides it between the
copies, but that glue separates two butt caps, and a cap ends where its path
ends: every gap shows as a hole in the stroke, one stroke width wide at the
stretch of an ordinary justified line. `\cleaders` splits the remainder between
the two ends and reaches neither last character.

So the append callback writes the copies instead. It is the one place where the
width of the piece is final — the packed box carries `glue_set`, and a glue's
actual width is its natural width plus its share of the box's stretch or shrink
— and there `tile` divides that width into `round(w / period)` whole cells and
replaces the leaders glue with one copy of the leader box per cell at
`floor(w / k)` followed by a kern of the remainder: no glue between the copies,
nothing left at either end, and the period follows the stretch of the line.
That width comes from `glue_set` together with `glue_sign`, since `glue_set`
stays positive on a shrunk line.

What a copy does with its cell depends on what it holds. A drawing is scaled:
its ink is painted inside a scope scaled horizontally to the cell, because the
drawing's own period is one em and the cell is not. The scale must be undone
without losing the advance the backend expects, so the closing literal carries
the `Q` and a translation of one period, and a copy drops l3draw's record of the
drawing's origin (a box of no width holding only whatsits), because every copy
would record the same label and the manual then reports `multiply defined`. A
symbol is a glyph, which does not scale: its copy keeps its size, and a kern of
half the leftover in front of it centres it in the cell. `tile` writes copies
for both, so the wave, the slash, `\CJKunderanysymbol`, `\CJKunderanyline` and
the `symbol` of the wave and the dots start at the left edge of their span; a
leader that is a rule, or a box that reduces to one solid rule, is left to
`\leaders`; the dots keep their leader box of no ink; and a box that never
reaches a vertical list keeps the plain `\leaders` remainder. The wave has a
period of one em and an amplitude of a quarter em.

The `depth` key places the rule below the baseline. `boxdepth`, which used to
cap how much a rule added to the box, is gone: it was a workaround for the
drawn patterns growing the line, and on a rule it removed the rule itself.

### The emphasis dots place their ink in the text

`\CJKunderdot` is the one decoration whose ink is not a pattern in the leaders
box. A pattern repeats on a fixed period, so it drifts against the characters
when the inter-character glue stretches, it runs under Latin text, and it
cannot give each character exactly one mark. The dots therefore go into the
text: the underline type has an empty leader box — it exists only for the
width, stretch, and shrink that `lua-ul` books — and the pass writes one dot
behind each CJK character.

A dot is a box of no width, height, or depth, so the line keeps its width and
leading; inside it a kern of half the advance and half the dot puts the ink at
the centre of the character, and an inner box shifted down by
`em descent + depth` holds a `rule` of `0.06em`. The nodes copy the attributes of the character, which
carries both the color of the text and the settings entry, and the dot box
carries `LuaCJKfntef.dot`, so a list the pass sees twice is not dotted twice.
`format` cannot travel by attribute from the TeX side — the attribute value is
resolved by `luaul_apply_color:` — so the TeX side reads the value of
`luacolor`'s attribute inside a group and hands it to Lua, which sets it on the
`rule`.

`subtract` keeps its meaning as a distance from each end: a character whose
centre falls in the inset part gets no dot, so half an em removes nothing from
a span of whole characters and a whole em removes its first and its last.  The
two bounds are those of the span and they travel into a box unchanged, so a
character inside an `\mbox` is measured from the edge of the span rather than
from the edge of its box.
`skip` leaves the punctuation undotted, and `hidden` still runs after the dots
are written, so a hidden span keeps them while its glyphs become kerns.

### Drawn decorations stay out of the metrics

The wave and the xout slash are drawings rather than leaders of a rule. Each is
built at use time inside `\l_@@_fntef_pattern_box`, and the box is then set to
zero height and depth, so the pattern reaches the page as a PDF literal without
entering the dimensions of the line. That is why a decorated line keeps the
leading of a plain one.

Two properties of `l3draw` shape the code. Its box is the bounding box of the
*stroked* path, one stroke width wider than the path, so a tiled pattern is
wrapped in `\hbox to <period>` with `\hss` on both sides and the period stays
exact instead of leaving a stroke-wide gap. It also places the drawing by the
bottom of that box, which lifts a path that goes below the baseline, so the
xout slash is lowered again by the part below the baseline plus half the
stroke. The wave's period is one em and its amplitude a quarter em, so a span
of whole characters is an exact number of periods and the crest lands in the
same place in every character; the drawn type's key carries the em alone. The
`symbol` variants of `\CJKunderdot` and `\CJKunderwave`, and
`\CJKunderanysymbol`, follow one placement rule: one symbol per em, centered in
the cell, its top a given distance under the *bottom of the em box*. The
measured descent is part of the cached type key, so a font change does not
reuse a stale placement.

The color of a drawn pattern travels in the drawing, not in an attribute.
`l3draw` strokes with the color `l3color` holds, so an attribute set by
`luacolor` cannot reach the ink; worse, it leaks: `luacolor` writes the color
before a leaders box and restores it only when it meets a later node that
carries an attribute, and a repeated box leaves none behind. The type is
therefore built without `\luaul_apply_color:`, and the pattern writes the
operations of `\current@color` — `format` resolved in a group of its own, or the
color of the text — right after `\draw_begin:`, inside the graphics scope of
`l3draw`. They are expanded when the box is built, since a literal expands its
payload at shipout, when that variable holds another call's color.

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

The range list repeats `CJK_RANGES`, limited to the Basic Multilingual Plane,
and `scripts/check-docs.sh` compares the two. The supplementary planes would
triple the string pool of the run for ideographs a listing almost never holds:
with them, one listing reaches 177 668 strings and 200 684 control sequences
against 45 865 and 68 881. Both ends of a range belong to it — the loop tests
after the body, not before — because a mark that opens a range (U+FF01, or a
curly quote in a range of its own) would otherwise stay outside the table:
`listings` would typeset it at scan time, next to the wrong text and one column
wide, which is the bug that a mark of `CJK_RANGES` outside the four ranges the
patch used to carry produced.

A run of CJK characters is one token, so `emph` and `keywords` can name a CJK
word: the run stays in `\lst@token` until `listings` ends a letter run, which
is why `\lst@AppendLetter` and `\lst@AppendOther` are wrapped. The wrapper must
*end* with the macro it calls, not merely call it and close a conditional
afterwards: `\lst@Append` takes the character that follows the active character
in the input as its argument, so a closing `\fi` or brace would be taken
instead. A CJK mark is its own token, because `listings`
treats a word in front of the mark as part of the mark's token otherwise; the
marks are `LuaCJK.punct_codes`, which filters the punctuation groups to the
character table, so the policy lives in one place. That list reaches TeX
through `tex.sprint(-2, …)`, the catcode table of other characters: the
listing has made printable ASCII active by then, and a list printed with the
current table would give active digits (`listings02`).

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

`\CJKfilltwosides` is a `minipage`. The environment sets its body in
`\minipage[position]{width}` — a width of zero or less passes `\linewidth` —
inside a group that gives the inter-character glue an infinite stretch, and
leaves everything else to the kernel: `\parindent` and `\parskip` are zero, so
a paragraph after a paragraph break starts at the left edge of the box and is
filled like the first; the leading is the document's own rather than the
`\lineskip` an enclosing alignment would impose; `\\` is `\@normalcr`, so a
table cell can hold the environment; and `\leavevmode` leaves vertical mode,
so the box joins the paragraph that follows, the text after the environment
stays on the same line, and a space after `\end` is ignored.

The `t`, `c`, and `b` positions are the kernel's: `t` is a `\vtop`, `b` the
natural box, and `c` the kernel's text `\vcenter`, centred on
`\Umathaxis\textstyle` after `\check@mathfonts`. A `\footnote` inside the body
is the minipage's: it is set at the bottom of the box, below the rule, and
numbered with the box's own counter, because `\@mpfootnotetext` keeps the note
in `\@mpfootins` and `\endminipage` unpacks that box into the vlist. A
hand-rolled `\vbox` cannot do either: the insert would be discarded at shipout,
and the settings above would have to be copied from the kernel one by one.

Tagging follows from that. `latex-lab`'s minipage module patches
`\@iiiminipage` and `\endminipage`, so around the box it ends the paragraph
structure, opens a `text-minipage` for the body, and reopens the paragraph
after it; the package opens no MC of its own and turns no paragraph hook off.
The module is loaded by any `\DocumentMetadata`, so a document that tags gets
the structure without the package knowing whether tagging is on.

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
`LoadFandol`, eight decorations in `LuaCJKfntef` with fifteen options, tagged
PDF output, and `LuaCJK-listings`.

The input characters are split in two at load time. U+180E, U+200B, U+2060, and
U+FEFF carry nothing a font can use and are given category code 9, so they
never reach the shaper. U+200C, U+200D, and the variation selectors keep their
category codes, because a font shapes with them: `pre_shaping` marks them, lets
them follow the font of the character in front of them, and `drop_orphans`
removes the placeholder where the font had no use for them, so they still take
no glue and do not split a CJK run (`zwchars01`).  The legacy path without
`pre_shaping_filter` removes both kinds at the input, since it has no pass to
tell them apart.

Deliberately absent, with the reason recorded in the manual: `RubberPunctSkip`
(the advance is a fixed kern, which is not a break opportunity and takes no
part in justification), `CheckFullRight` (the node list no longer shows the
following control sequence — use `\LuaCJKnobreak`), and `ulem`'s option list
(`LuaCJKfntef` builds on `lua-ul`). `PoZheHaoLigature` needs no option now that
the font shapes the text: a font that joins two em dashes into one two-em dash
does so on its own. Picking a backend inside `ctex` is now a public option
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
- Emphasis reaches CJK text through the family's italic face, never through the
  Latin italic: a family that names no `ItalicFont` stays upright under
  `\emph` and `\itshape` unless `AutoFakeSlant` is on.  The Fandol base set
  gives its roman family `FandolKai-Regular.otf` — emphasis in Chinese is Kai,
  which is what ctex's own fandol fontset does — and both the main declaration
  and `zhsong` carry it, because one family name holds one feature set and the
  later declaration would otherwise drop it.
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
l3build check <name>                # the local loop; must print "All checks passed"
l3build save <name>                 # only after inspecting why the baseline moved
l3build check                       # 78 tests, CI on every push
bash scripts/ctex-subset.sh         # 21/21, CI; no log may mention luatexja
bash scripts/check-docs.sh          # guides, and the two documentation languages
```

A change is verified here with the test it touches; the full suite, the manual
and the `ctex` subset are CI's, as the global `repo-rules` skill states.

When a change touches a pass, add a test that inspects nodes rather than
guessing from widths alone: walk `tex.box[0].head` and report the glue, kern,
and penalty nodes, then assert the numbers in the `.tlg`.
Existing examples are `decoration01` (the leaders pair), `selectable01` (the
`ActualText` wrapper and the `selectable` key), `tagging01` (tagged
decorations and the paragraph `CJKfilltwosides` joins), `settingsscope01`
(a group that closes before `\par`), `nobreak01`/`nobreak02` (penalties),
`nobreak03` (the penalty field of a discretionary),
`nobreak04` (a prohibiting penalty and the boundary glue),
`listings01` (glyph order and columns inside a listing), `listings02`
(the colour of every character around a token boundary), `ctex01`, the class test that
shows the engine file is reached through `engine = luacjk`, and `ctex02`,
which traps the `CJKfntef` refusal by overriding `\msg_critical:nn`.
