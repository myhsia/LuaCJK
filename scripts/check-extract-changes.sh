#!/usr/bin/env bash
# Does scripts/extract-changes.lua still reproduce ctex-kit's changelogs?
#
#   bash scripts/check-extract-changes.sh [--quiet]
#
#   exit 0  all six packages identical (clean)
#   exit 1  a package differs            (the Lua port or ctex-kit is stale)
#   exit 2  cannot run: no texlua, no ../ctex-kit, or a dirty ctex-kit
#
# The six committed changelogs of ctex-kit are the reference output of their
# scripts/extract-changes.py, and this repository's extractor is a port of it.
# The comparison is byte for byte; `--quiet` prints only the failures, which
# is what a session check wants.
#
# This script is the repository's session check: AGENTS.md declares it, and
# the `upkeep` plugin runs it once a day and after a directory change, so a
# change in ctex-kit reaches the next session instead of waiting for someone
# to remember.  It stays out of CI: a runner has no ../ctex-kit.
set -u
cd "$(dirname "$0")/.." || exit 2

quiet=no
[ "${1:-}" = "--quiet" ] && quiet=yes
note() { [ "$quiet" = yes ] || printf 'NOTE: %s\n' "$1" >&2; }

command -v texlua >/dev/null 2>&1 || { note "texlua is not on the path"; exit 2; }
kit=../ctex-kit
[ -d "$kit" ] || { note "$kit is not a checkout"; exit 2; }
[ -z "$(git -C "$kit" status --porcelain 2>/dev/null)" ] ||
  { note "$kit has uncommitted changes, the comparison is ambiguous"; exit 2; }

tmp=$(mktemp -d) || { note "cannot create a temporary directory"; exit 2; }
trap 'rm -rf "$tmp"' EXIT

status=0
for pkg in ctex xeCJK xpinyin zhlineskip zhmetrics zhnumber; do
  # shellcheck disable=SC2046
  files=$(ls -1 "$kit/$pkg"/*.dtx | LC_ALL=C sort)
  # shellcheck disable=SC2086
  if ! texlua scripts/extract-changes.lua $files all -o "$tmp/$pkg.md"; then
    printf 'FAIL       %s (the extractor failed)\n' "$pkg"
    status=1
  elif cmp -s "$kit/$pkg/CHANGELOG.md" "$tmp/$pkg.md"; then
    [ "$quiet" = yes ] || printf 'IDENTICAL  %s\n' "$pkg"
  else
    printf 'DIFFERS    %s\n' "$pkg"
    diff -u "$kit/$pkg/CHANGELOG.md" "$tmp/$pkg.md" | sed -n '1,12p'
    status=1
  fi
done
exit "$status"
