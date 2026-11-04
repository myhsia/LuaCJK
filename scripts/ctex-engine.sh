#!/usr/bin/env bash
# Run ctex from CTAN/TeX Live with the engine file that LuaCJK ships.
# The file is copied into the run directory, because \input searches the
# current directory first; that is also how a document can pick it up
# without touching the ctex installation.

set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"

skip_unpack=0
if [ "${1:-}" = "--skip-unpack" ]; then
  skip_unpack=1
fi

if [ "$skip_unpack" -eq 0 ]; then
  echo "== unpacking LuaCJK =="
  if command -v l3build >/dev/null 2>&1; then
    l3build unpack >/dev/null
  elif command -v l3build.bat >/dev/null 2>&1; then
    l3build.bat unpack >/dev/null
  elif command -v l3build.exe >/dev/null 2>&1; then
    l3build.exe unpack >/dev/null
  else
    echo "l3build not found; run 'l3build unpack' first and use --skip-unpack" >&2
    exit 1
  fi
fi

run="$root/build/ctex-shadow-run"
rm -rf "$run"
mkdir -p "$run"

cp build/unpacked/*.sty "$run/"
cp build/unpacked/ctex-engine-luatex.def "$run/"
cp build/unpacked/*.lua "$run/"
cp test/ctex/ctex-smoke.tex "$run/"

echo "== running ctex smoke test =="
cd "$run"
if ! lualatex -interaction=nonstopmode -halt-on-error \
       ctex-smoke.tex >run.out 2>&1; then
  cat run.out
  exit 1
fi

echo "== verifying the engine file =="
grep -q 'LuaCJK ctex engine loaded' ctex-smoke.log
# The path TeX resolved must be the copy in the run directory.
grep -q 'ctex-engine-luatex.def' ctex-smoke.log
grep -qE '^\(./ctex-engine-luatex\.def' ctex-smoke.log
if grep -q 'luatexja.sty' ctex-smoke.log; then
  echo "LuaTeX-ja was loaded; the LuaCJK engine file was not used" >&2
  exit 1
fi

echo "== verifying CJK output =="
grep -q 'LuaCJK ctex smoke: glyph 20013 font FandolSong' ctex-smoke.log

echo "== verifying behavioural checks =="
if grep -q 'LuaCJK ctex check FAIL' ctex-smoke.log; then
  grep 'LuaCJK ctex check FAIL' ctex-smoke.log >&2
  exit 1
fi
grep -q 'LuaCJK ctex check PASS: quanjiao compresses adjacent punctuation' ctex-smoke.log
grep -q 'LuaCJK ctex check PASS: single punctuation is not compressed' ctex-smoke.log
grep -q '^PENALTIES [1-9]' ctex-smoke.log
grep -q '^LINE_START_PERIODS 0$' ctex-smoke.log
grep -q '^GLYPH 20013$' ctex-smoke.log

echo "ctex engine test passed"
