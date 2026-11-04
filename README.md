[![CTAN Version](https://img.shields.io/ctan/v/luacjk)](https://ctan.org/pkg/luacjk)
[![GitHub Release](https://img.shields.io/github/v/release/myhsia/LuaCJK)](https://github.com/myhsia/LuaCJK/releases/latest)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/myhsia/LuaCJK)](https://github.com/myhsia/LuaCJK/commits)
[![Actions Status](https://github.com/myhsia/LuaCJK/workflows/Automated%20testing/badge.svg)](https://github.com/myhsia/LuaCJK/actions)
[![GitHub Repo stars](https://img.shields.io/github/stars/myhsia/LuaCJK)](https://github.com/myhsia/LuaCJK)

# LuaCJK

LuaCJK is a LuaTeX package for Chinese typesetting.

The package provides a CJK font family layer, CJK/CJK and CJK/Latin
spacing, the `quanjiao`, `plain`, `banjiao`, `kaiming`, `CCT`, and
`hangmobanjiao` punctuation styles with line-breaking prohibitions, and
fallback fonts, all on top of LuaTeX node callbacks. The companion package
`LuaCJKfntef` adds underlining, emphasis dots, and strike-through through
`lua-ul`. `LuaCJK-listings` keeps CJK text in place and two columns wide
inside a `listings` block.

## Loading

```tex
\usepackage{LuaCJK}
\setCJKmainfont{FandolSong-Regular.otf}
```

LuaCJK requires LuaLaTeX. It must not be loaded together with `luatexja`.

## Using it with ctex

`ctex` inputs an engine file whose name it fixes itself, so LuaCJK ships its
own `ctex-engine-luacjk.def` (a different name, to stay clear of the file that
`ctex` installs) and a short redirect that tells `ctex` about it. Create the
redirect once, in any document:

```tex
\documentclass{article}
\usepackage{LuaCJK}
\LuaCJKwriteCtexConfig
```

That writes `ctexopts.cfg` into the current directory. `ctex` inputs that file
before it loads its engine file, so every `ctex` document compiled from that
directory then uses LuaCJK instead of LuaTeX-ja. The redirect only acts
on LuaTeX, so XeLaTeX documents in the same directory keep their own backend.

## License

This work may be distributed and/or modified under the conditions of the
LaTeX Project Public License, version 1.3c or later.
