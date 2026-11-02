# LuaCJK

LuaCJK is a LuaTeX package for Chinese typesetting, inspired by `xeCJK`.

The project is currently at an early development stage. The first public
release provides a CJK font family layer and basic CJK/CJK and CJK/Latin
spacing on top of LuaTeX node callbacks. Punctuation compression, CJK
mathematics, and the decoration layer are planned for later releases.

## Loading

```tex
\usepackage{luacjk}
\setCJKmainfont{FandolSong-Regular.otf}
```

LuaCJK requires LuaLaTeX. It must not be loaded together with `luatexja`,
`luatex-cn`, or `xeCJK`.

## License

This work may be distributed and/or modified under the conditions of the
LaTeX Project Public License, version 1.3c or later.
