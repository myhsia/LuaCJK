#!/usr/bin/env bash
#=============================================================================
#    CHECK EXTRACT CHANGES: the Lua extractor against ctex-kit's changelogs
#=============================================================================
# Usage: bash scripts/check-extract-changes.sh [--quiet]
# Exit: 0 identical, 1 differs, 2 cannot run.
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
