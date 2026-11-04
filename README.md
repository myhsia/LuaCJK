[![CTAN Version](https://img.shields.io/ctan/v/luacjk)](https://ctan.org/pkg/luacjk)
[![GitHub Release](https://img.shields.io/github/v/release/myhsia/LuaCJK)](https://github.com/myhsia/LuaCJK/releases/latest)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/myhsia/LuaCJK)](https://github.com/myhsia/LuaCJK/commits)
[![Actions Status](https://github.com/myhsia/LuaCJK/workflows/Automated%20testing/badge.svg)](https://github.com/myhsia/LuaCJK/actions)
[![GitHub Repo stars](https://img.shields.io/github/stars/myhsia/LuaCJK)](https://github.com/myhsia/LuaCJK)

# LuaCJK

LuaCJK is a LuaTeX package for Chinese typesetting, inspired by `xeCJK`.

The project is currently at an early development stage.  The package
provides a CJK font family layer, CJK/CJK and CJK/Latin spacing, the
`quanjiao`, `plain`, `banjiao`, `kaiming`, `CCT`, and `hangmobanjiao`
punctuation styles with line-breaking prohibitions, and fallback fonts, all
on top of LuaTeX node callbacks.  The companion package `LuaCJKfntef` adds
underlining, emphasis dots, and strike-through through `lua-ul`.
`LuaCJK-listings` keeps CJK text in place and two columns wide inside a
`listings` block.

## Loading

```tex
\usepackage{LuaCJK}
\setCJKmainfont{FandolSong-Regular.otf}
```

LuaCJK requires LuaLaTeX. It must not be loaded together with `luatexja`.

## Using it with ctex

`ctex` looks for a file named `ctex-engine-luatex.def` and inputs it, so
LuaCJK ships that file and `ctex` then uses LuaCJK instead of LuaTeX-ja.
Since `ctex` installs a file of the same name, the LuaCJK copy has to be
found first: keep it in the document directory, or install it into a tree
that comes before the TeX Live main tree. A copy next to the one of `ctex`
is ignored.

## License

This work may be distributed and/or modified under the conditions of the
LaTeX Project Public License, version 1.3c or later.
