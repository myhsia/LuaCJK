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
