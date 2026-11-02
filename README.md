# LuaCJK

LuaCJK is a LuaTeX package for Chinese typesetting, inspired by `xeCJK`.

The project is currently at an early development stage. The first public
release provides a CJK font family layer, basic CJK/CJK and CJK/Latin
spacing, the `quanjiao`, `plain`, `banjiao`, `kaiming`, and `CCT`
punctuation styles, and basic punctuation line-breaking prohibitions on top of LuaTeX node callbacks. The other
punctuation presets, fallback fonts, and the decoration layer are planned for
later releases.

## Loading

```tex
\usepackage{LuaCJK}
\setCJKmainfont{FandolSong-Regular.otf}
```

LuaCJK requires LuaLaTeX. It must not be loaded together with `luatexja`
or `xeCJK`.

## License

This work may be distributed and/or modified under the conditions of the
LaTeX Project Public License, version 1.3c or later.
