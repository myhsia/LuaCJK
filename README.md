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

LuaCJK requires the LuaTeX engine.
It must not be loaded together with `luatexja`.

## Tagged PDF

Declare `\DocumentMetadata{tagging = on}` before `\documentclass` to
produce a tagged PDF.
The ink of a decoration is an artifact, a decoration symbol is left out of
the text a reader copies, and `LuaCJKfntef`'s `selectable` key keeps a
symbol as text.
Under `l3doc`, load `latex-lab-testphase-l3doc` as well.
The manual is built with tagging enabled.

## Using it with ctex

Pass `engine = luacjk` to the `ctex` class or package:

```tex
\documentclass[engine = luacjk]{ctexart}
```

`ctex` then inputs `ctex-engine-luacjk.def` instead of its own LuaTeX
backend, and that file loads LuaCJK, so the package is not loaded separately.

## License

This work may be distributed and/or modified under the conditions of the
LaTeX Project Public License, version 1.3c or later.
