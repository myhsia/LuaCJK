#!/usr/bin/env bash
#
# Report the open issues that carry no subsystem label, so that a session can
# categorise them: one subsystem label, which is the commit scope of the fix.
# The type of an issue (Bug, Feature, Task) is GitHub's native issue type, not
# a label, so it plays no part here.
#
# Exit 0 when every open issue has a subsystem label, 1 when some do not (one
# line each on stdout, `#<number> <title>`), and 2 when the check cannot run
# here: no `gh`, no `jq`, no authentication, no GitHub remote, or no network.

set -u

command -v gh >/dev/null 2>&1 || exit 2
command -v jq >/dev/null 2>&1 || exit 2
gh auth status >/dev/null 2>&1 || exit 2

# The subsystem labels are the commit scopes listed in AGENTS.md; an issue that
# carries none of them still has to be categorised.
subsystems='["core","fonts","chars","punct","spacing","breaks","verbatim",
             "options","load","fntef","listings","ctex","math","manual",
             "readme","doc","build","ci","layout","style"]'

issues=$(gh issue list --state open --limit 200 --json number,title,labels \
           2>/dev/null) || exit 2
printf '%s' "$issues" | jq -e 'type == "array"' >/dev/null 2>&1 || exit 2

unlabelled=$(printf '%s' "$issues" | jq -r --argjson subsystems "$subsystems" '
  .[]
  | select(([.labels[].name] - $subsystems) == [.labels[].name])
  | "#\(.number) \(.title)"')

[ -n "$unlabelled" ] || exit 0
printf '%s\n' "$unlabelled"
exit 1
