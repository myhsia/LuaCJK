# Changelog

## 0.1.0 (2026-11-02)

- Initial development release.
- Provide the CJK font family interface (`\setCJKmainfont`,
  `\setCJKsansfont`, `\setCJKmonofont`, `\setCJKfamilyfont`, `\CJKfamily`,
  `\newCJKfontfamily`, `\CJKfontspec`).
- Replace CJK glyph nodes in `pre_linebreak_filter` and `hpack_filter` using a
  LuaTeX attribute that records the current CJK font.
- Add basic CJK/CJK and CJK/Latin spacing with `CJKglue`, `CJKecglue`,
  `CJKspace`, and `xCJKecglue`.
- Add box, math, and transparent-node boundary handling.
- Add the `PunctStyle` interface with working `quanjiao`, `plain`,
  `banjiao`, `kaiming`, `CCT`, and `hangmobanjiao` styles.
- Add `PunctKinsoku` line-breaking prohibitions: closing punctuation cannot
  start a line, opening punctuation cannot end a line, and long punctuation
  runs are kept together.
- Add `CJKmath` and `\setCJKmathfont` for typing CJK characters directly in
  math mode, including nested math lists such as fractions.  A one-time
  warning is issued when CJK characters appear in math mode while `CJKmath`
  is off.
- The ctex shadow test now asserts punctuation, kinsoku, and CJK math
  behaviour instead of only checking that the document compiles.
- Document the package with `l3doc` and `docext` under LuaLaTeX.
- Use the `LuaCJK` spelling for the package and derived files; the l3build/CTAN module stays `luacjk`.
- Accept the same keys as package options, for example
  `\usepackage[PunctStyle = banjiao]{LuaCJK}`.  Unknown keys warn instead of
  raising an error.
- Use the public LaTeX3 Lua interfaces (`\lua_now:e`, `\lua_escape:e`,
  `\lua_load_module:n`) instead of `\directlua` and `kpse.findfile`.
- Add `\LuaCJKdisable` and `\LuaCJKenable` to suspend the typographic
  adjustments while keeping CJK font selection.
- Split the Lua code into `LuaCJK.lua` (entry point) and `LuaCJK-core.lua`.
- Add `LuaCJKfntef`, a `lua-ul` based companion package providing
  `\CJKunderline`, `\CJKunderdot`, and `\CJKsout`.
- Suspend the adjustments automatically in `\verb`, `verbatim`, `fancyvrb`
  and `listings` environments; `\LuaCJKdisable` now records its state per
  node.
- Warn only once for an unknown CJK family.
- Inserted glue, kerns, and penalties now inherit the attributes of the
  neighbouring node, so attribute-based decorations such as
  `\CJKunderdot` stay in one piece across CJK/CJK and CJK/Latin boundaries.
- Only `luatexja` is rejected now; `xeCJK` already refuses to run outside
  XeTeX, so LuaCJK no longer duplicates that check.
- Add `\defaultCJKfontfeatures` and `\addCJKfontfeatures`.
- Add `\normalspacedchars` so that slashes, backslashes, and hyphens take
  no glue on either side.
- Add `\LuaCJKsetwidth` and `\LuaCJKsetkern` for per-mark widths and
  per-pair gaps that override the selected punctuation style.
- Add the `Verb` option (`true`, `env`, `env+`, `false`) to control what
  happens inside `\verb` and the verbatim-like environments.
- Add the `LocalConfig` option, which reads `luacjk.cfg` or
  `luacjk-<name>.cfg` at the end of the package.
- Add `AutoFakeBold`, `AutoFakeSlant`, `EmboldenFactor`, and `SlantFactor`;
  a family that sets `BoldFont` or `ItalicFont` keeps its real faces.
- Add `\setCJKfallbackfamilyfont` and `AutoFallBack` for characters that
  the selected CJK font does not have.
- Add the `LoadFandol` option, which supplies Fandol fonts when the
  document declares none.
- Add `\LuaCJKDeclareCharClass`, `\LuaCJKDeclarePunctClass`, and
  `\LuaCJKResetCharClass` to override the class of a code-point range.
- Add `CheckSingle` and `WidowPenalty`, which stop a single CJK character
  from ending up alone on the last line of a paragraph.
- Add `\CJKunderdblline`, `\CJKunderwave`, and `\CJKxout` to
  `LuaCJKfntef`; the wave and the slash are drawn with `l3draw` and
  repeated with leaders, so they stay in phase along a line.
- Add `KaiMingPunct`, `MiddlePunct`, `LongPunct`, and `NoBreakLongPunct`,
  each with `+` and `-` forms, to edit the punctuation character sets.
- Add `\LuaCJKEditPunctStyle` and `AllowBreakBetweenPuncts`.
- Add `PunctFamily`, which sets a separate CJK family for the punctuation
  marks.
- `\CJKunderline` now takes `thickness`, `depth`, and `textformat`, and
  passes any other key on to `lua-ul`.
- Add the `CJKfilltwosides` environment, which justifies its lines to a
  given width and places the box on the baseline as requested.
- Document a comparison with `xeCJK` that separates what is available with
  the same meaning, what differs, and what is missing.
- Add `\LuaCJKnobreak` and the `PunctWidth` option.
- `\CJKunderline` accepts `format` for the colour of the rule; it takes a
  colour name rather than code.
- Add `\CJKunderanyline` and `\CJKunderanysymbol` for arbitrary rules and
  repeated symbols; the underline type is cached by the arguments.
- Add `\LuaCJKDeclareSubCJKBlock` with `\LuaCJKCancelSubCJKBlock` and
  `\LuaCJKRestoreSubCJKBlock`, so a range of characters can use its own
  font inside a family.
- Add `PunctBoundWidth`, which leaves only the given advance inside the
  line and hangs the rest of the mark into the margin; it replaces the fixed
  half-em shift of `hangmobanjiao`.
- Add `\LuaCJKShipoutHook`, which runs code through the standard
  `shipout/before` hook.
- `subtract` and `skip` now work for `\CJKunderdblline`, `\CJKunderwave`,
  `\CJKxout`, and `\CJKunderdot` as well as `\CJKunderline`.
- `\CJKunderline` accepts `subtract` (inset at both ends) and `skip`
  (leave out the punctuation).  The decoration boxes of lua-ul are adjusted
  in place: the leaders width is reduced and a matching kern and negative
  glue keep the text where it was.
- Add the fntef option `hidden`, which keeps the dimensions of the text but
  draws no glyph.
- Add `\LuaCJKVerbAddon` and `\LuaCJKOffVerbAddon`, which make one CJK
  character as wide as two spaces of the current monospaced font and forbid
  breaks between CJK characters, so columns in code listings stay aligned.
- Add `LatinPunct`, which keeps the shared quotation marks, the middle dot,
  and the ellipses in the Latin font instead of the CJK font.
- Every setting now travels with the characters: a snapshot of the options is
  stored once and recorded on the glyphs, so a group that ends before the
  paragraph does still decides how its own text is set.  This covers
  `CJKglue`, `CJKecglue`, `PunctStyle`, `PunctKinsoku`, `LatinPunct`,
  `CJKmath`, `PunctWidth`, `PunctBoundWidth`, `CheckSingle`, `WidowPenalty`,
  and `AllowBreakBetweenPuncts`.
- The default `CJKglue` and `CJKecglue` are recomputed at every font
  selection, so they follow `\small`, `\Large`, and `\zihao` instead of
  staying at the value of the 10pt size.
- `AutoFallBack` and the cancelled sub-blocks follow the group now.  Both
  are part of the settings snapshot, so `{\LuaCJKsetup{AutoFallBack=true} ...}`
  and `{\LuaCJKCancelSubCJKBlock{...} ...}` end with their group.
- `\LuaCJKnobreak` and `\LuaCJKVerbAddon` keep their prohibition when
  `PunctKinsoku` is off; the switch only controls the punctuation rules.
- The manual now separates the settings that follow the text from the global
  and load-time keys.
- Ship `ctex-engine-luacjk.def` as the LuaTeX backend for ctex.  The name
  differs from the file that ctex installs, so both packages can be installed
  side by side and CTAN has no duplicate file.
- Add `\LuaCJKwriteCtexConfig`, which writes a `ctexopts.cfg` redirect into
  the document directory.  ctex inputs that file after it has fixed the
  engine file name and before it loads the engine file, so the redirect takes
  effect in the same run; `ctexbackend.cfg` is read too early and `ctex.cfg`
  too late.
- The test-only `support/ctex` directory is gone.  The ctex smoke test is a
  normal test file now (`testfiles/ctex01.lvt`), so `l3build check` exercises
  the engine file on every run; the subset script fails if any of the ctex
  tests falls back to LuaTeX-ja.
- The underline geometry now uses `depth=0.2em` and `thickness=0.4pt` on
  every path, so `format` works without also giving `thickness` or `depth`.
  `top` and `bottom` still override the computed values.
- Add `gap` to `\CJKunderdblline`, `symbol` and `sep` to `\CJKunderwave` and
  `\CJKunderdot`, and `height` and `thickness` to `\CJKsout`.
- `\CJKsout` now takes the same key list as the other decorations, including
  `format` and `subtract`; a bare color name is still accepted.
- Add `LuaCJK-listings`, which keeps CJK characters in place inside a
  `listings` block, counts each of them as two columns, and turns the spacing
  adjustments off.  LuaCJK loads it automatically with `listings`.
- `\LuaCJKDeclareCharClass` accepts the class names of `xeCJK`
  (`FullLeft`, `FullRight`, `HalfLeft`, `HalfRight`, `NormalSpace`,
  `CJStarter`, `CM`, `Boundary`); `\LuaCJKResetCharClass` also restores the
  normal-spaced set.
- Drop the placeholder glyph that a font without the character leaves behind
  (one `.notdef` glyph in some fonts, a private-use glyph in others).
- Move the manual driver into `LuaCJK.dtx` and use the same fonts as
  `ctxdoc.cls`; the manual is now built from the `.dtx` alone.
- Close the gap between two periods of `\CJKunderwave`: the drawing box now
  has exactly the period width, and the two `\hss` absorb the stroke width,
  so the wave is continuous and no overfull box is reported.
- `\CJKunderwave`, `\CJKunderdot`, and `\CJKxout` now build their pattern at
  use time, so the wave period, the dots, and the slash scale with the font
  size instead of keeping the size of the font current when the package was
  loaded.
- `\CJKsout` now strikes at `height=0.3em` by default, which passes through
  the middle of a CJK glyph; `height=0.5ex` restores the Latin position.
- The slash of `\CJKxout` now runs from `-0.15em` to `0.8em`, so it crosses
  the whole body of a CJK glyph instead of stopping in its upper half.
- The drawn patterns of `\CJKunderwave`, `\CJKunderdot`, and `\CJKxout`
  are built in a box whose height and depth are zero, so a decoration no
  longer opens up the line it sits on.  The wave and the dots used to add
  about `0.25em` of depth.  The `boxdepth` key, which only existed to limit
  that growth, is removed; it also erased the rule of a `\vrule`-based
  decoration when used there.
