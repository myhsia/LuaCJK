#!/usr/bin/env bash
# Test-only bridge: run ctex from CTAN/TeX Live with the LuaCJK shadow
# engine file.  The shadow file is never installed into the TeX tree.

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

stage="$root/build/ctex-shadow"
run="$root/build/ctex-shadow-run"
rm -rf "$stage" "$run"
mkdir -p "$stage" "$run"

echo "== building shadow ctex-engine-luatex.def =="
cp support/ctex/ctex-engine-luatex.dtx \
   support/ctex/ctex-engine-luatex.ins "$stage/"
if ! (cd "$stage" &&
      pdftex -interaction=nonstopmode ctex-engine-luatex.ins >ins.log 2>&1); then
  cat "$stage/ins.log"
  exit 1
fi

cp build/unpacked/LuaCJK.sty "$run/"
cp build/unpacked/*.lua "$run/"
cp "$stage/ctex-engine-luatex.def" "$run/"
cp test/ctex/ctex-smoke.tex "$run/"

echo "== running ctex smoke test =="
cd "$run"
if ! lualatex -interaction=nonstopmode -halt-on-error \
       ctex-smoke.tex >run.out 2>&1; then
  cat run.out
  exit 1
fi

echo "== verifying shadow engine =="
grep -q 'LuaCJK ctex shadow engine loaded' ctex-smoke.log
grep -q 'ctex-engine-luatex.def' ctex-smoke.log
if grep -q 'luatexja.sty' ctex-smoke.log; then
  echo "LuaTeX-ja was loaded; the shadow engine was not used" >&2
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

echo "ctex shadow test passed"
