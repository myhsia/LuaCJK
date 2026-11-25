## [LuaCJK-v0.1.1](https://github.com/myhsia/LuaCJK/releases/tag/LuaCJK-v0.1.1)

- A paragraph that begins with a box hangs the opening mark inside it as well, so `\mbox` around the mark leaves its blank in the indentation, as a line of plain text does.

## [LuaCJK-v0.1.0](https://github.com/myhsia/LuaCJK/releases/tag/LuaCJK-v0.1.0)

- `Baseline` moves the characters of the family in force where they are written, and the marks of the family `PunctFamily` names, so a family selected inside a group moves only that group and two declarations of one font keep their values in the same paragraph.
- The punctuation group `latin-close` can be declared and removed like the others, so the spacing of the ASCII closing marks is a setting of the document and not only a default.
- The two- and three-em dashes `U+2E3A` and `U+2E3B` are CJK characters of the dash group, so a font that joins a pair of em dashes into one glyph keeps the prohibition of `NoBreakLongPunct`.
- `\LuaCJKnobreak` forbids the breaks inside its argument alone: a break at either edge of the argument is the business of the text around it, and the glue the package inserts behind the last character no longer carries the prohibition.
- `\CJKfontspec` switches the text to its font even when `PunctFamily` names a family, which used to replace the family name the command was about to select.
- The initial list holds the two characters it documents, the slash and the hyphen: the list is read as a sequence of characters, so the commas that separated them used to be normal-spaced as well, and so did the space between two of them. A backslash is not in it, because beside a CJK character it usually begins a printed command name, which takes the glue on both of its sides like any other Latin character.
- `LoadLXGW` replaces `LoadFandol` and supplies the LXGW family when the document declares no CJK font.
- A CJK--Latin boundary takes the settings of the CJK character it touches, so `CJKecglue` follows the size of the CJK text: a Latin run set with `\scriptsize` or `\large` keeps the space of the surrounding text on both of its sides.
- The ASCII closing marks are a punctuation group of their own: a `!`, `,`, `.`, `:`, `;`, `?`, `%`, `"`, or `'` takes the zero-width boundary glue beside a CJK character and may not start a line, and it keeps the advance the Latin font gave it, which no compression style, no hang, and no `PunctWidth` touches.
- A box takes the class of the text nearest its edge, so a kern, a spacing glue, or a rule inside it no longer hides that text: `\mbox` around an italic `\textit` keeps the `CJKecglue` beside its last letter, a box that holds no text takes the glue on both sides, and a filling glue still leaves the edge empty, which keeps the titles of a table of contents aligned.
- A vertical box reads its edges by the same rule, so the rule that underlines a `\underline` no longer hides the text above it: the underlined Latin run takes the `CJKecglue` on both of its sides, like the run a `\mbox` or `\CJKunderline` holds.
- A box the edge holds does not hide the text behind it when that box has no class of its own, and a paragraph line is read past its `local_par` marker: `\parbox` takes the `CJKecglue` at the edge its first character reaches, while its last edge stays empty, because `\parfillskip` does not let the text reach it.
- A box that holds nothing on its own baseline, only raised or lowered boxes, is attached like a shifted box: the mark of `\footnote` and `\raisebox` therefore take no glue on either side, as the box `\textsuperscript` builds already did.
- A framed box is an object of the line and not a mark: `\fbox`, `\framebox` and `\fcolorbox` lower a vertical box around their content, so they take the `CJKecglue` on both sides like any other box, while the mark of `\raisebox` or a `\footnote` still takes none.
- A node inserted at a CJK--Latin boundary keeps only the attributes both characters carry, so a decoration ends at the last character it covers: the `CJKecglue` behind `\CJKunderline`'s argument no longer takes the rule past it.
- A suspended run takes the glue its two classes give at its edge: `\verb` beside a CJK character is spaced as the same characters in a text font are, while the material itself is left alone.
- A source space beside a box that occupies no advance belongs to the boundary of the two characters the box stands between: the space in front of the box becomes the inter-character glue, so an `\mbox` between two CJK characters takes no `CJKglue` of its own, and two spaces on either side of it are one space.
- The gap between two adjacent marks is the blank between their ink: the length `\LuaCJKsetkern` gives is that blank, so `0pt` makes the two marks meet instead of widening the gap, and a compression takes at most the blank the compressed mark carries on its right.
- A formula that sets one opening or closing delimiter alone is that bracket: the CJK--Latin glue stands outside the pair and not between the delimiter and the text it encloses, so the angle brackets of a `\meta` argument hug their Chinese characters.
- A half-width closing bracket keeps the `CJKecglue` between itself and the CJK character that follows it, so the outside of a pair of brackets is spaced on both sides while the pair still hugs the text it encloses.
- The glue stands in front of the background a colour box draws: the highlight of `\colorbox` covers the box it was asked to colour and not the space between the two characters, so it stops the same distance from the text on both sides.
- A ratio style never cuts into the ink: a mark keeps its ink and the smaller of its two blanks, so the fullwidth percent sign and the fullwidth currency signs keep their advance under `banjiao` and no longer overlap the character after them.
- The advance a ratio style gives a mark and the place of its ink come from the outline, so a mark whose ink is not against the edge of its box keeps a blank on both sides instead of losing part of the ink.
- The ink of a glyph is measured at the extremum of its curves rather than at their control points, and the alternating curve operators read the abscissa of their third point from the operand that carries it, so the blank a mark hangs is the blank its outline paints.
- The blank of a glyph on each side is read from its outline, so the gap `\LuaCJKsetkern` gives and the amount a compression takes are the blanks the font carries.
- The last line of a centered or flush-right paragraph hangs the mark it ends with as well, so every line of it stops at the same edge instead of the last one standing the width of that blank further in.
- The cell of a repeated symbol starts at the left edge of the decorated span, so `\CJKunderanysymbol` keeps the symbol of a single character whose span begins in the middle of a cell; `\CJKunderanyline` and the `symbol` of `\CJKunderdot` and `\CJKunderwave` follow the same rule.
- The body of `CJKfilltwosides` is set as a `minipage`, so a paragraph after a paragraph break starts at the left edge of the box and is filled like the first one, and the leading between the lines is the leading of the document instead of whatever an enclosing alignment left behind.
- A `\footnote` inside `CJKfilltwosides` is set at the bottom of the box and numbered with the box's own counter, instead of being lost with the insert that a plain vertical box cannot hold.

## [LuaCJK-v0.0.4](https://github.com/myhsia/LuaCJK/releases/tag/LuaCJK-v0.0.4)

- A run of CJK characters inside an `lstlisting` block is one token of `listings`, so a `emph` or `keywords` entry that names a CJK word highlights it; a Latin character and a CJK mark both end the run.
- `Baseline` belongs to the declaration that writes it, so a fallback font and a family that name the same font keep their own offsets.
- `HalfLeft` and `HalfRight` declare a half-width ASCII bracket: it keeps its advance, does not hang, and hugs the text inside the pair, where they used to declare a full-width opening or closing mark.
- `\LuaCJKnobreak` forbids the break at a glue the document writes inside its argument, so a `\quad` or an `\hspace` there no longer starts a line.
- The font of a CJK family is resolved in the Unicode encoding: a document that sets its Latin text in an 8-bit encoding with `fontenc` keeps its CJK text.
- The family `\CJKfamilydefault` names is selected when the document starts, so a preamble that redefines it sets the main text in that family from the first line.
- An untouched `\CJKfamilydefault` follows `\familydefault` at the start of the document, so a preamble that redefines `\familydefault` sets the main text in the matching CJK family.
- `\defaultCJKfontfeatures` reaches the font of a sub-block and of a fallback font as well.
- `\CJKfontspec` no longer reads an option list after the font name, so a bracket that the text starts with is no longer swallowed.
- A code point below U+0100 in a font that is not Unicode-encoded is a position in that font's encoding, not a character, so a symbol font's slot is no longer read as a CJK character: `pifont`'s slot 0xB7, the circled 2, keeps its own font and prints.
- With `LatinPunct` on, the midline ellipsis U+22EF stays in the Latin font like the other shared marks that key lists.
- The punctuation table covers the marks `xeCJK` classes as opening or closing, so the percent sign U+FF05 no longer starts a line and the currency symbols no longer end one; the halfwidth and compatibility forms and the three hyphen-like marks follow the same class.
- The ASCII brackets are punctuation marks of their own: a half-width opening bracket no longer ends a line and a half-width closing bracket no longer starts one, the pair hugs the text between it, and a compression style leaves the bracket's own advance alone.
- A space in front of a color change keeps its advance: the whatsit a `\textcolor` inserts no longer hides the space from the boundary rules, so no `CJKecglue` or second `CJKglue` joins it.
- A suspended run keeps the break opportunity beside it: the zero-width glue at its edge lets `\verb` end a line next to a CJK character while the spacing stays removed.
- A punctuation mark is given its fixed advance once: a box that holds the list is packed again, and the mark no longer takes a second compensating kern, so a fixed-width style no longer squeezes a table cell or a parbox.
- The first line of a list item hangs as well: the label box that the list writes in front of the item's text is passed over, so a mark that begins the item leaves its blank in the label's advance.
- A centered or flush-right paragraph does not hang the mark it begins with: the line does not start at the edge of the measure, so the shift would move the whole line instead of leaving the blank in a margin that is not there.
- A CJK character ends a word for hyphenation, so the line breaker no longer puts a hyphen beside a CJK character, and the boundary keeps the `CJKecglue` that the two sides give it.
- `hidden` hides a formula as it hides text: a character or a rule inside a box of the span carries no ink, so a fraction is hidden like a plain number and keeps its width, height, and depth.
- `format` is resolved at every call, so a color that `\colorlet` redefines between two decorations is followed by the second one instead of keeping the color of the first.
- The wave is written one period at a time, so it covers the start and the end of a span that is not a whole number of periods, on a stretched line as well as on the last line of a paragraph.
- The slashes are written one cell at a time, so they cover the whole span.
- A CJK character inside a box gets its dot wherever the box sits in the span, so `\mbox` no longer drops the dot of a character in the middle of the text.
- `CJKfilltwosides` works inside a table cell: it gives `\\` the meaning it has in a `\parbox` within its group, so the enclosing alignment no longer takes the line break.
- `CJKfilltwosides` leaves vertical mode as `\parbox` does, so the text after it joins the box on the same line instead of beginning a paragraph, and a space after the environment is ignored as `xeCJK` ignores it.

## [LuaCJK-v0.0.3](https://github.com/myhsia/LuaCJK/releases/tag/LuaCJK-v0.0.3)

- A mark that the CJK class shares with Latin, such as a curly quotation mark or the em dash, keeps its place inside an `lstlisting` block and counts as two columns: the character table covers the CJK ranges of the Basic Multilingual Plane, both ends of each included.
- The punctuation the two scripts share is a CJK character: the middle dot (U+00B7), the horizontal bar (U+2015), the two dot leader (U+2025), the hyphenation point (U+2027), and the midline ellipsis (U+22EF) are set in the CJK font, and `LatinPunct` keeps the ones it lists in the Latin font; the two dot leader joins a run of dashes and ellipses that may not be broken.
- An explicit `\ ` or `\nobreakspace` between two CJK characters keeps its advance: a space from the source is retimed to the inter-character glue, and one the document wrote itself is not.
- Process the package options after the helpers their key codes call, so that `AutoFallBack`, `CJKmath`, `PunctFamily`, and `CJLineBreak` act as package options as well.
- `PunctWidth` and `PunctBoundWidth` take `0pt` as a length: the former gives every mark no advance and the latter hangs the whole of it, where a zero length used to act as `false` and return the mark to its style.
- The addon turns the adjustments back on in its group, so the columns of a verbatim-like environment stay aligned under `Verb` = `true` and `env` as well; `\LuaCJKOffVerbAddon` restores the suspension that was in force.
- The `Verb` option also reaches the inline `\Verb` and `\UseVerb` of `fancyvrb`, which never select `\verbatim@font` and are set as `\verb` sets them; the block commands `\VerbatimInput` and `\UseVerbatim` follow the environments instead.
- A document whose default CJK family is not declared is reported, and its text takes a family it did declare instead of none at all.
- `PunctFamily` shifts its marks by the `Baseline` of the family it names.
- The three sizes of a CJK math family come from the text size of the formula, so a `\text` inside it no longer sets the other characters of the formula in a script size.
- A CJK character in math mode takes a fallback font when the CJK font of the formula does not have it.
- `\setCJKfamilyfont` expands the name of the family it declares, so a family can be given as `\CJKrmdefault` and friends.
- `\CJKfamily` expands its argument, so a family can be given as `\CJKrmdefault` and friends.
- The joiners (U+200C, U+200D) and the variation selectors are no longer removed at the input: they reach the font, so an emoji sequence is not split and a CJK variation sequence selects its glyph, and what the font leaves of them is dropped before the spacing pass, so two CJK characters still take no glue around them.
- `LoadFandol` is on by default, so a document that declares no CJK font is set in the four Fandol faces without asking for them.
- `LoadFandol` gives the roman family `FandolKai-Regular.otf` as its italic face, so `\emph` and `\itshape` set the text in Kai instead of leaving it upright.
- The CJK font is applied to the characters before the text is shaped instead of to the glyph nodes after it: a combining mark attaches to its base, a variation sequence selects its glyph, and the font's own ligatures and `locl` forms appear. An older `luaotfload` keeps the previous behavior.
- A joiner or a variation selector that the font cannot use leaves nothing behind, and neither does a CJK character the CJK font does not have.
- A box that occupies no advance is passed over: `\rlap`, `\llap` and `\clap` overlay ink on the text around them, so they no longer take a `CJKecglue` on either side.
- A superscript or subscript set with `\textsuperscript` or `\textsubscript` stays with the character in front of it: the shifted box takes no glue on either side, so no break is offered before it.
- A penalty that prohibits the break no longer removes the glue: the CJK--CJK and CJK--Latin spacing survives `\nobreak`, because the glue goes after the penalty, where the prohibition still covers it. A source space in front of the penalty is converted and the penalty moves in front of it.
- `\hfill` after `\textbf` keeps its fill: only a glue of normal order counts as a source space, so the fill of the line is no longer turned into the inter-character glue.
- A dash or an ellipsis cannot start a line either: a break in front of a run of them is forbidden, so the run travels to the next line whole, while the break between the marks of a run stays the business of the `NoBreakLongPunct` set.
- The blank of a mark is measured from the charstring the glyph uses, so a glyph whose charstring calls a subroutine is measured in the subroutine rather than in the charstring the measurement began with.
- A curve of four operands is read as one curve in both axes, so the blank of a mark whose charstring draws it with the alternating or the vertical curve operator is the blank the glyph has: a double opening quotation mark no longer stands in the margin by more than a tenth of a point.
- An opening mark that begins a paragraph, or a line the document forces a break at, hangs as well: its blank stands in the indentation or in the margin, and `PunctBoundWidth` decides how much of the advance stays inside the line there too.
- A whatsit between two CJK characters no longer hides the break point from `CheckSingle`: a color change, a mark, and the other nodes that carry no text are passed over, so they no longer leave a single character on the last line.
- `top` and `bottom` are keys of the decoration, so they reach a rule that `format` colors as well, and an underline type is built per font size, so a rule built from `em` units keeps its thickness when the size changes.
- A decoration keeps the width, the stretch, and the shrink of the text it covers, so a rule no longer changes the spacing of the line it sits in, `skip` no longer tightens a justified line, and a `\kern` inside the text no longer moves the gap `skip` leaves at a punctuation mark.
- `hidden` takes the ink out of the text instead of putting it in a `\phantom`: the text keeps its line breaks, so a hidden paragraph breaks like the visible one instead of overflowing in one line.
- The wave takes `format` like the other decorations: the pattern is stroked in that color, in the color of its text when the key is absent, and neither color reaches the text outside it.
- The wave is a smooth arch of one period per em, a quarter em above and below the underline; a decoration is divided into whole patterns once its final width is known and the pattern is drawn at that width, so the periods meet without a gap, the wave reaches the last character, and its period follows the stretch of the line.
- The slash takes `format` like the wave, and follows the color of its text when the key is absent.
- The slash is divided into whole cells once its width is final, so the slashes cover the span evenly and the last one reaches its end.
- The emphasis dots sit under each CJK character, centred in the one-em cell of the character; Latin letters, digits, and spaces carry none, and the dots follow the characters when the inter-character glue stretches.
- The `t` and `c` positions of `CJKfilltwosides` place the box as `\parbox` does: `t` puts the baseline of its first line on the surrounding baseline, and `c` centres the box on the text axis instead of on the baseline.

## [LuaCJK-v0.0.2](https://github.com/myhsia/LuaCJK/releases/tag/LuaCJK-v0.0.2)

- `Baseline` shifts the glyphs of the font that declares it, so two CJK fonts whose baselines do not match can be set side by side.
- `\LuaCJKnobreak` also forbids the break at a `discretionary`, so an explicit hyphen or an automatic hyphenation point inside the argument no longer breaks the line.
- Restore `\CJKfamilydefault` when `\normalfont` or `\textnormal` runs, so that the default font command overrides a family chosen earlier in the group; `\CJKfamilydefault` follows `\CJKrmdefault` until the document sets it.
- The fallback list is resolved again at every font selection, so the fallback follows the series, shape, and size of the text.
- A CJK character in a formula takes the face of the math version: the bold face of the family under `\boldmath` when the family has one, and the upright shape instead of the shape of the text.
- `\CJKfontspec` and `\newCJKfontfamily` take their options after the font name as well.
- The space in front of `\textbf` and its siblings is still the inter-character glue: LaTeX moves a space across the italic correction of a text font command, and the move leaves the glue with the subtype of a skip the document wrote.
- `AllowBreakBetweenPuncts` no longer lets a closing mark start a line or an opening mark end one, and a mark inside a box takes part in the prohibitions.
- The hang of a mark is the blank its font carries, read from the outline, so the ink of a line-final or line-initial mark stands on the measure instead of half an em inside it; a file that cannot be read falls back to half the advance.
- The hanging of a mark takes part in line breaking, so a line that ends at a closing mark or begins with an opening mark holds the mark the margin allows; the ink of that mark stands outside the line, and `PunctBoundWidth` decides how much of the advance stays inside.
- The double rule takes `format` like the other decorations, and a rule or a symbol that carries no `format` follows the color of the surrounding text.

## [LuaCJK-v0.0.1](https://github.com/myhsia/LuaCJK/releases/tag/LuaCJK-v0.0.1)

- Provide the CJK font family interface (`\setCJKmainfont`, `\setCJKsansfont`, `\setCJKmonofont`, `\setCJKfamilyfont`, `\CJKfamily`, `\newCJKfontfamily`, `\CJKfontspec`); an undeclared family warns once.
- Provide `LuaCJK-listings`, which keeps CJK characters in place inside a `listings` block and counts each of them as two columns; `LuaCJK` loads it automatically with `listings`.
- Ship `ctex-engine-luacjk.def` as the LuaTeX backend for `ctex`, selected with the option `engine = luacjk`; like `ctex`'s own backend it refuses `CJKfntef` and points at `LuaCJKfntef`.
- Refuse to load with `luatexja`.
- Provide `\LuaCJKversion`, which prints the version of the package.
- Provide the `PunctStyle` key with the `quanjiao`, `plain`, `banjiao`, `kaiming`, `CCT`, and `hangmobanjiao` styles. Under a style with a fixed width the advance of an opening or middle mark moves its ink with it.
- Provide `\LuaCJKEditPunctStyle` to edit the punctuation sets of the current style, and `AllowBreakBetweenPuncts`.
- Provide `\LuaCJKsetwidth` and `\LuaCJKsetkern` for per-mark widths and per-pair gaps that override the selected punctuation style.
- Provide `\LuaCJKDeclareSubCJKBlock` with `\LuaCJKCancelSubCJKBlock` and `\LuaCJKRestoreSubCJKBlock`, so a range of characters can use its own font inside a family.
- Provide `\LuaCJKDeclareCharClass`, `\LuaCJKDeclarePunctClass`, and `\LuaCJKResetCharClass` to override the class of a code-point range. The classes carry the names of `xeCJK` (`FullLeft`, `FullRight`, `HalfLeft`, `HalfRight`, `NormalSpace`, `CJStarter`, `CM`, `Boundary`), the reset also restores the normal-spaced set, and the built-in table covers the CJK blocks of Unicode 15 and 16.
- Provide `\LuaCJKDeclarePunctStyle` for a punctuation style of your own, with the keys `compress-adjacent`, `adjacent-ratio`, and `keep-open-close`.
- Provide `AutoFakeBold`, `AutoFakeSlant`, `EmboldenFactor`, and `SlantFactor`; a family that sets `BoldFont` or `ItalicFont` is not emboldened or slanted.
- Provide `\LuaCJKsetup`, and accept the same keys as package options, for example `\usepackage[PunctStyle = banjiao]{LuaCJK}`; an unknown key warns.
- Every setting travels with the characters: a snapshot of the options is recorded on the glyphs, so a group that ends before its paragraph decides how its own text is set.
- Provide `\LuaCJKdisable` and `\LuaCJKenable` to suspend the typographic adjustments while keeping CJK font selection; the state is recorded per node.
- Provide `\LuaCJKShipoutHook`, which runs code through the standard `shipout/before` hook.
- Provide `\LuaCJKnobreak` and the `PunctWidth` option; neither this prohibition nor that of `\LuaCJKVerbAddon` depends on `PunctKinsoku`, which controls only the punctuation rules.
- Provide `\LuaCJKVerbAddon` and `\LuaCJKOffVerbAddon`, which make one CJK character as wide as two spaces of the current monospaced font and forbid breaks between CJK characters, so columns in code listings stay aligned.
- Suspend the adjustments inside `\verb` and the verbatim-like environments (`verbatim`, `fancyvrb`, `listings`); the `Verb` option (`true`, `env`, `env+`, `false`) controls what is suspended there.
- Provide `PunctFamily`, which sets a separate CJK family for the punctuation marks.
- Provide `\defaultCJKfontfeatures` and `\addCJKfontfeatures`.
- Provide `\setCJKfallbackfamilyfont` and `AutoFallBack` for characters that the selected CJK font does not have.
- Provide `\songti`, `\heiti`, `\fangsong`, `\kaishu`, `\lishu`, and `\youyuan` as shorthands for the families `zhsong`, `zhhei`, `zhfs`, `zhkai`, `zhli`, and `zhyou`.
- Provide `\normalspacedchars` so that slashes, backslashes, and hyphens take no glue on either side.
- Ignore the zero-width format characters (U+200B, U+200C, U+200D, U+2060, U+180E) and the variation selectors at the input, so that they neither take glue nor separate two CJK characters.
- Provide the `LocalConfig` option, which reads `luacjk.cfg` or `luacjk-<name>.cfg` at the end of the package.
- Provide the `LoadFandol` option, which supplies Fandol fonts when the document declares none.
- Provide `CJLineBreak`, which forbids a line break before the characters whose Unicode `Line_Break` property is `CJ`.
- Provide `KaiMingPunct`, `MiddlePunct`, `LongPunct`, and `NoBreakLongPunct`, each with `+` and `-` forms, to edit the punctuation character sets.
- A character the font lacks leaves no placeholder: the `.notdef` or private-use glyph a font substitutes for it is removed.
- Provide `LatinPunct`, which keeps the shared quotation marks, the middle dot, and the ellipses in the Latin font instead of the CJK font.
- Glue, kerns, and penalties inserted by the package carry the attributes of the neighbouring node, so a decoration such as `\CJKunderdot` covers CJK/CJK and CJK/Latin boundaries without a gap.
- Provide CJK/CJK and CJK/Latin spacing with `CJKglue`, `CJKecglue`, `CJKspace`, and `xCJKecglue`; a value keeps its stretch and shrink orders. A source space between two CJK characters becomes the inter-character glue, so the boundary keeps its break opportunity and its stretch, and no glue is inserted between two long punctuation marks.
- A mark keeps its break opportunity beside suspended text: the boundary glue at a mark has no width.
- Provide `PunctKinsoku` line-breaking prohibitions: closing punctuation cannot start a line and opening punctuation cannot end a line.
- Provide `CJKmath` and `\setCJKmathfont` for CJK characters in math mode, including nested math lists such as fractions. The family is registered as a math family, so a character in a script or a fraction keeps the size of that math style; with `CJKmath` off, a CJK character in math mode warns once.
- Provide `PunctBoundWidth`, which leaves only the given advance of a mark inside the line and hangs the rest into the margin, at the end of a line, at its start, and when the mark ends a box such as `\mbox`.
- Provide `CheckSingle` and `WidowPenalty`, which stop a single CJK character from ending up alone on the last line of a paragraph.
- Provide `LuaCJKfntef`, a `lua-ul` based companion package providing `\CJKunderline`, `\CJKunderdot`, and `\CJKsout`. `\CJKunderline` takes `thickness`, `depth`, `format` for the color of the rule, and any other key of `lua-ul`; the geometry defaults to `depth = 0.2em` and `thickness = 0.4pt`, and `top` and `bottom` override the computed values.
- Every decoration takes the same key set: `color`, `gap`, `height`, `symbol`, `sep`, `textformat`, and `hidden`, which keeps the dimensions of the text and draws no glyph. A bare color name is accepted, so `[red]` and `[subtract]` both work, and a key that a command does not use is ignored. Every decoration accepts `selectable`, `false` by default: a decoration symbol is then wrapped in an `ActualText` sequence that readers drop from the text they copy or select. Every decoration also accepts `subtract` (inset at both ends) and `skip` (leave out the punctuation). `\CJKsout` strikes at `height = 0.3em`, through the middle of a CJK glyph; `0.5ex` gives the Latin position.
- Provide `\CJKunderdblline`, `\CJKunderwave`, and `\CJKxout`; the wave and the slash stay in phase along a line, their patterns scale with the font size, a decoration does not open up its line, and it fills its span exactly.
- Provide `\LuaCJKemdescent`, the depth of the em box of the current font, so that an object of height `1em` placed at that depth covers the one-em square of a CJK character in any font.
- Provide `\CJKunderanyline` and `\CJKunderanysymbol` for arbitrary rules and repeated symbols; `\CJKunderanysymbol` puts one symbol per em, centered in the cell, its depth measured from the baseline to the top of the symbol.
- Provide the `CJKfilltwosides` environment, which justifies every line to a given width and places the box on the baseline as requested. It is tagged: a text block in vertical mode, part of the surrounding paragraph in horizontal mode.
