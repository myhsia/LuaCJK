#!/usr/bin/env bash
#
# The repository's session check.  A repository may declare one check in its
# guide, so this wrapper runs the two things a session has to know before it
# starts:
#
#   - the changelog extractor against ctex-kit's committed changelogs
#     (`scripts/check-extract-changes.sh`), and
#   - the open issues that still carry no subsystem label
#     (`scripts/triage-issues.sh`).
#
# Exit 0 silent, 2 when neither part can run here, and 1 with one summary line
# per part that needs attention.

set -u

drift=$(bash scripts/check-extract-changes.sh --quiet 2>/dev/null)
drift_status=$?
issues=$(bash scripts/triage-issues.sh 2>/dev/null)
issues_status=$?

status=0

if [ "$drift_status" -ne 0 ] && [ "$drift_status" -ne 2 ]; then
  printf 'ctex-kit changelog drift: %s\n' "$(printf '%s\n' "$drift" | head -1)"
  status=1
fi

if [ "$issues_status" -ne 0 ] && [ "$issues_status" -ne 2 ]; then
  numbers=$(printf '%s\n' "$issues" | awk '{ printf "%s%s", sep, $1; sep = ", " }')
  count=$(printf '%s\n' "$issues" | wc -l | tr -d ' ')
  printf '%s open issue(s) without a subsystem label: %s (run scripts/triage-issues.sh)\n' \
    "$count" "$numbers"
  status=1
fi

if [ "$status" -eq 0 ] && [ "$drift_status" -eq 2 ] && [ "$issues_status" -eq 2 ]; then
  exit 2
fi
exit "$status"
