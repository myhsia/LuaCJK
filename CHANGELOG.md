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
- Document the package with `l3doc` and `docext` under LuaLaTeX.
