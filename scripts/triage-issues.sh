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
# The keyword table decides the suggestion and the first match wins, so its
# order is the design: an issue that mentions both `\CJKunderline` and
# `CJKglue` belongs to `fntef`, because that is where the reports of one
# decoration pass land.  An issue that matches no rule gets no label at all and
# stays in the report, so the classifier never invents a category; a session
# reads it and labels it by hand.

set -u

usage() {
  sed -n '3,23p' "$0" | sed 's/^# \{0,1\}//'
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

# label, then a case-insensitive extended regular expression on the title and
# body.  Keep the rules narrow: a wrong label is worse than no label, because
# nothing reports it afterwards.
rules=$(cat <<'RULES'
fntef	LuaCJKfntef|CJKunderline|CJKunderwave|CJKunderdot|CJKunderanyline|CJKunderanysymbol|CJKsout|underline|xout
math	CJKmath|boldmath|amsmath|mathsf
punct	PunctStyle|PunctWidth|setwidth|setkern|EditPunctStyle|punct
load	LoadFandol|AutoFallBack|fallback|zhspacing|kotex
fonts	setCJK|CJKfontspec|newCJKfontfamily|CJKfamily|fakebold|fakeslant|BoldFont
breaks	AllowBreakBetweenPuncts|kinsoku|CJKunbreakable|nobreak|linebreak|断行|禁则
chars	DeclareCharClass|DeclarePunctClass|DeclareSubCJKBlock|CharClass|SubCJKBlock
spacing	CJKglue|CJKecglue|normalspacedchars|spacing|间距
verbatim	verbatim|lstlisting|LuaCJK-listings|fancyvrb
ctex	ctex-engine|engine = luacjk|usepackage{ctex}
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
  issue=$(gh issue view "$number" --json number,title,body,labels 2>/dev/null) || exit 2
  issues="[$issue]"
else
  issues=$(gh issue list --state open --limit 200 --json number,title,body,labels \
             2>/dev/null) || exit 2
fi
printf '%s' "$issues" | jq -e 'type == "array"' >/dev/null 2>&1 || exit 2

# A tab-separated record per issue, one line each: a title or a body that
# contains a tab or a newline is folded to a space, so the record survives the
# `read` loop below.
records=$(printf '%s' "$issues" | jq -r --argjson subsystems "$subsystems" \
  --argjson keep "$([ "$explain" = true ] && echo true || echo false)" '
  .[]
  | select($keep or (([.labels[].name] - $subsystems) == [.labels[].name]))
  | [ .number
      , (.title | gsub("[\\t\\n\\r]"; " "))
      , ((.body // "") | gsub("[\\t\\n\\r]"; " ")) ]
  | map(tostring) | join("\t")')

[ -n "$records" ] || exit 0

status=0
while IFS=$'\t' read -r num title body; do
  [ -n "${num:-}" ] || continue
  if suggestion=$(classify "$title"$'\n'"$body"); then
    if [ "$apply" = true ]; then
      gh issue edit "$num" --add-label "$suggestion" >/dev/null 2>&1 ||
        { printf '#%s could not be labelled\n' "$num"; status=2; continue; }
      printf '#%s %s (%s)\n' "$num" "$suggestion" "$title"
    else
      printf '#%s %s (%s)\n' "$num" "$suggestion" "$title"
      [ "$explain" = true ] || { [ "$status" -eq 0 ] && status=1; }
    fi
  else
    printf '#%s unclassified (%s)\n' "$num" "$title"
    [ "$explain" = true ] || { [ "$status" -eq 0 ] && status=1; }
  fi
done <<< "$records"

exit "$status"
