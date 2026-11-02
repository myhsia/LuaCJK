#!/usr/bin/env bash
# Test-only bridge: run ctex from CTAN/TeX Live with the LuaCJK shadow
# engine file.  The shadow file is never installed into the TeX tree.

set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"

echo "== unpacking LuaCJK =="
if [ "${OS:-}" = "Windows_NT" ]; then
  l3build_cmd=l3build.bat
else
  l3build_cmd=l3build
fi
"$l3build_cmd" unpack >/dev/null

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

cp build/unpacked/luacjk.sty build/unpacked/luacjk.lua "$run/"
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

echo "ctex shadow test passed"
