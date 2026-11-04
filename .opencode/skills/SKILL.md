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

LuaCJK sets Chinese text on LuaTeX the way `xeCJK` does on XeTeX, but through
node callbacks instead of XeTeX character classes.  This skill carries the
architecture: which callback does what, what each attribute means, how a
punctuation style is expressed, and why the decorations are adjusted rather
than drawn.  It exists so that a change to the pipeline does not have to be
reverse-engineered from the Lua source first.

## Repository rules

Repo etiquette, the git/PR workflow, LaTeX style, tooling and upkeep are
**machine-global**: see the `repo-rules` skill.  Build commands, the file
layout, and the validation criteria are in the repository's `AGENTS.md`.

## Background

### Passes and where they run

The character-level passes run in `pre_linebreak_filter` and in
`hpack_filter` (the source is `local function process`):

1. `rewrite_fonts` — point each CJK glyph at the font family recorded on it
   (`\g_LuaCJK_font_attr`), then at the punctuation family or a sub-block font
   if one applies, then at a fallback font when the target lacks the glyph.
2. `spacing` — remove the source space between CJK characters, and insert
   `CJKglue`/`CJKecglue` at every boundary between two classes of character.
3. `apply_fixed_widths` — give punctuation the advance the style asks for, by
   inserting a penalty and a kern before the mark.
4. `apply_kinsoku` — insert a `\penalty 10000` at a break point the
   line-breaking prohibitions forbid.
5. `apply_check_single` — raise the penalty at the last two break points of a
   paragraph, so a single character cannot end up alone on the last line.

`post_linebreak_filter` runs `hang_punctuation` on the packed lines: it shifts
the ink of a mark at the start or the end of a line (hanging punctuation), and
with `PunctBoundWidth` it shifts a line-final mark so that only the given
advance stays inside the line.  Only `xoffset` changes, never a width, so
justification is untouched.

`pre_mlist_to_hlist_filter` runs `rewrite_math`, which turns a CJK character in
a math noad into a box in the CJK math font.

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
`\par`, and made `{\small ...}` use the glue of the outer size.  Now
`\LuaCJK_settings_push:` (called at the end of `\LuaCJKsetup` and after every
`\selectfont`) sends the current options to `LuaCJK.new_settings`, which
dedupes them by a signature string, stores the entry, and records its number in
the `settings` attribute.  Lua reads `settings_of(node)` and never the TeX
side.  Adding an option means touching all five places listed in `AGENTS.md`.

`CJKglue` and `CJKecglue` keep their registers, but the defaults
(`0pt plus 0.08\baselineskip` and `0.3333em plus 0.1667em minus 0.1111em`) are
recomputed at each font selection unless the document set them; a document
value is used as written.  That is what the `ccglue_touched` flags are for.

### The punctuation model

Every mark gets a group from `PUNCT_CLASS`: `open`, `close`, `middle`, `dash`,
`ellipsis`.  Four character sets are editable at run time
(`M.charsets`): `kaiming` (marks that stay full width in the `kaiming` style),
`middle`, `long` (never compressed against each other), and `nobreak` (never
separated by a line break).  A style (`M.punct_styles`) is a table of six
optional fields:

| field | effect |
| --- | --- |
| `compress_adjacent`, `ratio` | shorten the mark before another one by `ratio` of its width |
| `keep_open_close` | do not compress an opening against a closing mark |
| `fixed_ratio`, `fixed_full` | give every mark `fixed_ratio` of the em, except the `kaiming` set |
| `hanging` | shift line-initial and line-final marks by half an em |

The prohibitions in `forbids_break` are the ones that matter for correctness:
a closing or middle mark may not start a line, an opening mark may not end one,
and a run of `nobreak` long marks is one unit.  `AllowBreakBetweenPuncts` and
`PunctKinsoku` gate these, but an explicit `nobreak` attribute bypasses both.

### Decorations adjust, they do not draw

`LuaCJKfntef` builds on `lua-ul`, which represents a decoration as a leaders
glue of width *w* followed by a glue of width *-w* that gives the space back.
`LuaCJKfntef.lua` finds that pair in `hpack_filter` and
`pre_append_to_vlist_filter`, and replaces the leaders by a sequence of kerns
and shorter leaders whose total is still *w*; the text therefore does not move
while the rule is inset (`subtract`), left out over punctuation (`skip`), or
capped in depth (`boxdepth`).  The settings of one call live in
`LuaCJKfntef.settings`, numbered by the decoration attribute, so two
decorations in one paragraph keep their own settings.

A coloured rule cannot use `\color`, which emits whatsits in front of
`\leaders`; it goes through `luacolor`'s attribute colouring
(`\luaul_set_color:n` plus `\luaul_apply_color:`), which is why `format` takes
a colour name rather than code.

### The ctex adapter

`ctex` asks for an engine file under a name of its own choosing, so LuaCJK
ships `ctex-engine-luacjk.def` — the `ctex` interface (`\ctex_add_to_selectfont:n`,
`\ccwd`, `\CTEX@alchar`, `\ctex_set_jfm:n`, the `kanjiskip`/`xkanjiskip` keys)
implemented on top of LuaCJK.  Because the name differs, `ctex` only picks it
up when `ctexopts.cfg` redirects it; `\LuaCJKwriteCtexConfig` writes that file
once per directory.  `ctex` keeps its own copies of the two glues so it can
tell whether the document changed them; the engine file keeps the copies in
step and sets the `*_touched` flags, otherwise the next `\selectfont` would
restore the default and undo the user's `kanjiskip`.

## Current work

Implemented: font family layer with fake bold and slant, fallback fonts and
sub-blocks, `\CJKglue`/`\CJKecglue`/`xCJKecglue`/`CJKspace` with per-node
settings, six punctuation styles plus the character-set and style editing keys,
punctuation hanging and bound width, `CheckSingle`, `CJKmath`, `\LuaCJKnobreak`,
`\LuaCJKVerbAddon`, `\LuaCJKShipoutHook`, `LocalConfig`, `LoadFandol`, eight
decorations in `LuaCJKfntef` with twelve options, and `LuaCJK-listings`.

Deliberately absent, with the reason recorded in the manual: `PoZheHaoLigature`
(LuaTeX shapes one glyph at a time), `RubberPunctSkip` (the advance is a fixed
kern, not stretchable glue), `CheckFullRight` (the node list no longer shows the
following control sequence — use `\LuaCJKnobreak`), and `ulem`'s option list
(`LuaCJKfntef` builds on `lua-ul`).  Picking a backend inside `ctex` still needs
the agreement of the `ctex` maintainers; the redirect is the interim route.

## Conventions

- Lengths on the Lua side are integers in scaled points; dimensions cross the
  boundary through `\dim_to_decimal_in_sp:n`.
- Code-point ranges cross the boundary as a Lua list of `{first, last}` pairs,
  built from the `xeCJK` spelling (`"4E00 -> "9FFF`) in TeX.
- Glue crosses as a spec table `{width, stretch, shrink}`; `make_glue` and
  `set_glue` take that table, not a register name.
- A character class or punctuation override in `M.class_override` /
  `M.punct_override` always wins over `LatinPunct` and the built-in tables.
- `\LuaCJKsetwidth`, `\LuaCJKsetkern`, the four punctuation-set keys, and the
  `Declare*` commands are global by design; the manual says so at each of them.
- The manual is English; the package's user-facing prose keeps the same
  terminology as the code (`CJKglue`, `PunctStyle`, `subtract`) rather than
  inventing translations.

## Workflows and validation

The commands are in `AGENTS.md`.  For this skill the points that matter are:

```bash
l3build check                       # 37 tests, must print "All checks passed"
l3build save <name>                 # only after inspecting why the baseline moved
bash scripts/ctex-subset.sh         # 21/21, and no log may mention luatexja
```

When a change touches a pass, add a test that inspects nodes rather than
guessing from widths alone: walk `tex.box[0].head` and report the glue, kern,
and penalty nodes, then assert the numbers in the `.tlg`.  Existing examples
are `decoration01` (the leaders pair), `settingsscope01` (a group that closes
before `\par`), `nobreak01`/`nobreak02` (penalties), and `listings01` (glyph
order inside a listing).
