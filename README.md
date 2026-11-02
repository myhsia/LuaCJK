[![CTAN Version](https://img.shields.io/ctan/v/luacjk)](https://ctan.org/pkg/luacjk)
[![GitHub Release](https://img.shields.io/github/v/release/myhsia/LuaCJK)](https://github.com/myhsia/LuaCJK/releases/latest)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/myhsia/LuaCJK)](https://github.com/myhsia/LuaCJK/commits)
[![Actions Status](https://github.com/myhsia/LuaCJK/workflows/Automated%20testing/badge.svg)](https://github.com/myhsia/LuaCJK/actions)
[![GitHub Repo stars](https://img.shields.io/github/stars/myhsia/LuaCJK)](https://github.com/myhsia/LuaCJK)

# LuaCJK

LuaCJK is a LuaTeX package for Chinese typesetting, inspired by `xeCJK`.

The project is currently at an early development stage. The first public
release provides a CJK font family layer, basic CJK/CJK and CJK/Latin
spacing, the `quanjiao`, `plain`, `banjiao`, `kaiming`, `CCT`, and
`hangmobanjiao` punctuation styles, and basic punctuation line-breaking
prohibitions on top of LuaTeX node callbacks.  The companion package
`LuaCJKfntef` adds underlining, emphasis dots, and strike-through through
`lua-ul`.  Fallback fonts and the remaining decoration types are planned for
later releases.

## Loading

```tex
\usepackage{LuaCJK}
\setCJKmainfont{FandolSong-Regular.otf}
```

LuaCJK requires LuaLaTeX. It must not be loaded together with `luatexja`.

## License

This work may be distributed and/or modified under the conditions of the
LaTeX Project Public License, version 1.3c or later.
