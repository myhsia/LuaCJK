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
- Drop the placeholder glyph that a font without the character leaves behind
  (one `.notdef` glyph in some fonts, a private-use glyph in others).
- Move the manual driver into `LuaCJK.dtx` and use the same fonts as
  `ctxdoc.cls`; the manual is now built from the `.dtx` alone.
