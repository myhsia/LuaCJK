#!/usr/bin/env bash
#
# Categorise issues by subsystem: one label per issue, which is the commit scope
# of the fix.  The type of an issue (Bug, Feature, Task) is GitHub's native
# issue type, not a label, so it plays no part here.
#
# Without options it only reports, which is what the session check does: one
# line per open issue that carries no subsystem label, exit 0 none left, 1 some
# reported, 2 cannot ask GitHub.
#
#   --apply          add the label the keyword table suggests, for each issue
#                    that has none yet
#   --explain        print what the table suggests for every open issue,
#                    labelled or not, and change nothing; this is how a change
#                    to the table is judged
#   --number <n>     restrict the run to one issue, which is what the workflow
#                    on `issues: opened` does so that two runs cannot race
#
# The table reads the TITLE only, never the body.  A body is the reporter's
# apparatus, and it is nearly the same in every report of one reporter: this
# repository's are all `\usepackage[LoadFandol]{LuaCJK}` followed by
# `\setCJKmainfont{…}`, so a body scan labelled a question about `lstlisting`
# with `load` (#32) and a question about Japanese combining marks with `fonts`
# (#34).  The title is the part the reporter chose to name the defect with.
#
# The first match wins, so the order below is the design: an issue that names
# both `\CJKunderline` and `CJKglue` belongs to `fntef`, because that is where
# the reports of one decoration pass land.  An issue that matches no rule gets
# no label at all and stays in the report, so the classifier never invents a
# category; a session reads it and labels it by hand.
#
# `AutoFallBack` used to be part of the `load` rule.  Its fix lands in the
# option pipeline (`options`) or in the font layer (`fonts`) depending on the
# report, and no title says which, so it is not guessed: such an issue is left
# unclassified for a session to read.
#
# A font feature, and the interface that sets one, is the font layer:
# `\addCJKfontfeatures`, `CharacterWidth`, and the `hwid` tag are `fonts`,
# although the reporter meets them as an option.  A title that names `\hfill`
# is about the glue whose subtype the spacing pass decides, so it is `spacing`.
#
# A title whose only hook is a code point (`U+2027 的排版`) is about the
# character table, which is `chars`, so the code-point rule is the last one:
# first match wins, and an issue that also names a subsystem (`U+0027 的间距`)
# takes that subsystem, which is where its fix lands.

set -u

usage() {
  sed -n '3,30p' "$0" | sed 's/^# \{0,1\}//'
}

apply=false
explain=false
number=""

while [ $# -gt 0 ]; do
  case "$1" in
    --apply)    apply=true ;;
    --explain)  explain=true ;;
    --number)   shift; number="${1:-}" ;;
    -h|--help)  usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

command -v gh >/dev/null 2>&1 || exit 2
command -v jq >/dev/null 2>&1 || exit 2
gh auth status >/dev/null 2>&1 || exit 2

# The subsystem labels are the commit scopes listed in AGENTS.md.
subsystems='["core","fonts","chars","punct","spacing","breaks","verbatim",
             "options","load","fntef","listings","ctex","math","manual",
             "readme","doc","build","ci","layout","style","repo"]'

# label, then a case-insensitive extended regular expression on the title.
# Keep the rules narrow: a wrong label is worse than no label, because nothing
# reports it afterwards.  A key that names an interface (`PunctWidth`) belongs
# to the file that implements it, not to the file the reporter passes it from,
# and an option name is a rule only when it is the subject of the report, which
# is what reading the title guarantees.
rules=$(cat <<'RULES'
fntef	LuaCJKfntef|CJKunderline|CJKunderwave|CJKunderdot|CJKunderanyline|CJKunderanysymbol|CJKsout|下划线|波浪线|删除线|着重号|format=
listings	listing|lstlisting|LuaCJK-listings
verbatim	verbatim|fancyvrb
math	CJKmath|boldmath|amsmath|公式
punct	PunctStyle|PunctWidth|setwidth|setkern|EditPunctStyle|标点|禁则
load	LoadFandol
fonts	CJKfontspec|newCJKfontfamily|fakebold|fakeslant|BoldFont|字体|加粗|addCJKfontfeatures|CharacterWidth|hwid
breaks	AllowBreakBetweenPuncts|kinsoku|nobreak|断行|换行
chars	DeclareCharClass|DeclarePunctClass|SubCJKBlock|CharClass
spacing	CJKglue|CJKecglue|normalspacedchars|间距|空格|hfill
ctex	ctex-engine|engine = luacjk
chars	U\+[0-9A-Fa-f]{4,6}
RULES
)

classify() {
  local text=$1 label pattern
  while IFS=$'\t' read -r label pattern; do
    [ -n "${label:-}" ] || continue
    if printf '%s' "$text" | grep -qiE "$pattern"; then
      printf '%s' "$label"
      return 0
    fi
  done <<< "$rules"
  return 1
}

if [ -n "$number" ]; then
  issue=$(gh issue view "$number" --json number,title,labels 2>/dev/null) || exit 2
  issues="[$issue]"
else
  issues=$(gh issue list --state open --limit 200 --json number,title,labels \
             2>/dev/null) || exit 2
fi
printf '%s' "$issues" | jq -e 'type == "array"' >/dev/null 2>&1 || exit 2

# A tab-separated record per issue, one line each: a title that contains a tab
# or a newline is folded to a space, so the record survives the `read` loop.
records=$(printf '%s' "$issues" | jq -r --argjson subsystems "$subsystems" \
  --argjson keep "$([ "$explain" = true ] && echo true || echo false)" '
  .[]
  | select($keep or (([.labels[].name] - $subsystems) == [.labels[].name]))
  | [ .number, (.title | gsub("[\\t\\n\\r]"; " ")) ]
  | map(tostring) | join("\t")')

[ -n "$records" ] || exit 0

# Report mode is the session check: anything it prints needs attention, so it
# exits 1.  `--apply` and `--explain` are tools, and an issue the table declines
# to place is an outcome they print, not a failure.
report=false
[ "$apply" = false ] && [ "$explain" = false ] && report=true

status=0
while IFS=$'\t' read -r num title; do
  [ -n "${num:-}" ] || continue
  if suggestion=$(classify "$title"); then
    if [ "$apply" = true ]; then
      gh issue edit "$num" --add-label "$suggestion" >/dev/null 2>&1 ||
        { printf '#%s could not be labelled\n' "$num"; status=2; continue; }
      printf '#%s %s (%s)\n' "$num" "$suggestion" "$title"
    else
      printf '#%s %s (%s)\n' "$num" "$suggestion" "$title"
      [ "$report" = true ] && [ "$status" -eq 0 ] && status=1
    fi
  else
    printf '#%s unclassified (%s)\n' "$num" "$title"
    [ "$report" = true ] && [ "$status" -eq 0 ] && status=1
  fi
done <<< "$records"

exit "$status"
