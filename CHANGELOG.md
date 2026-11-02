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
  `banjiao`, `kaiming`, and `CCT` styles; `hangmobanjiao` still warns and
  falls back.
- Add `PunctKinsoku` line-breaking prohibitions: closing punctuation cannot
  start a line, opening punctuation cannot end a line, and long punctuation
  runs are kept together.
- Add `CJKmath` and `\setCJKmathfont` for typing CJK characters directly in
  math mode, including nested math lists such as fractions.
- The ctex shadow test now asserts punctuation, kinsoku, and CJK math
  behaviour instead of only checking that the document compiles.
- Document the package with `l3doc` and `docext` under LuaLaTeX.
- Use the `LuaCJK` spelling for the package and derived files; the l3build/CTAN module stays `luacjk`.
