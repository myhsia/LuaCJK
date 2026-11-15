[![CTAN Version](https://img.shields.io/ctan/v/luacjk)](https://ctan.org/pkg/luacjk)
[![GitHub Release](https://img.shields.io/github/v/release/myhsia/LuaCJK)](https://github.com/myhsia/LuaCJK/releases/latest)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/myhsia/LuaCJK)](https://github.com/myhsia/LuaCJK/commits)
[![Actions Status](https://github.com/myhsia/LuaCJK/actions/workflows/test.yaml/badge.svg?branch=main)](https://github.com/myhsia/LuaCJK/actions)
[![GitHub Repo stars](https://img.shields.io/github/stars/myhsia/LuaCJK)](https://github.com/myhsia/LuaCJK)

The `LuaCJK` Package
====================

The `LuaCJK` package provides Chinese typesetting for the LuaTeX engine.

It provides
- A CJK font family layer, with sub-blocks, fallback fonts, the Fandol
collection, and fake bold and slant.
- CJK/CJK and CJK/Latin spacing, and the prohibitions that keep a line from
breaking at the wrong place.
- The `quanjiao`, `plain`, `banjiao`, `kaiming`, `CCT`, and `hangmobanjiao`
punctuation styles.
- Underlining, emphasis dots, and strike-through, through the companion
package `LuaCJKfntef`.
- CJK text kept in place and two columns wide inside a `listings` block,
through the companion package `LuaCJK-listings`.
- Tagged-PDF output: with `\DocumentMetadata{tagging=on}` the ink of a
decoration is an artifact and a decoration symbol is left out of the text a
reader copies.  Under `l3doc`, load `latex-lab-testphase-l3doc` as well.

It runs on the LuaTeX engine only, and must not be loaded together with
`luatexja`.

Overview
--------

To load this package, write the line

    \usepackage{LuaCJK}

and then choose the CJK fonts, for example with

    \setCJKmainfont{FandolSong-Regular.otf}

A `ctex` document takes it through the `engine` option instead, and does not
load the package separately:

    \documentclass[engine = luacjk]{ctexart}

See `LuaCJK.pdf` for more. Happy TeXing!

Issues
------

The issue tracker for `LuaCJK` is currently located
[on GitHub](https://github.com/myhsia/LuaCJK/issues).

Build status
------------

This project uses [GitHub Actions](https://github.com/features/actions) as a
hosted continuous integration service. For each commit, the build status is
tested using the current release of TeX Live.

_Current build status:_
![build status](https://github.com/myhsia/LuaCJK/actions/workflows/test.yaml/badge.svg?branch=main)

Copyright and License
---------------------

Copyright (C) 2026 by Mingyu Xia
[`<myhsia@outlook.com>`](mailto:myhsia@outlook.com)

This work may be distributed and/or modified under the conditions
of the LaTeX Project Public License (LPPL), either version 1.3c of
this license or (at your option) any later version.
The latest version of this license is in

    http://www.latex-project.org/lppl.txt

and version 1.3c or later is part of all distributions of LaTeX
version 2008 or later.

This work has the LPPL maintenance status `maintained`.

The Current Maintainer of this work is **Mingyu Xia**.


