#!/usr/bin/env bash
#=============================================================================
#    CTEX SUBSET: ctex's own .lvt tests with the shipped engine file
#=============================================================================
# Usage: bash scripts/ctex-subset.sh [--skip-unpack]
# Exit: 0 all passed, 1 a test failed.
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

ctex_kit=${CTEX_KIT:-"$root/../ctex-kit"}
if [ ! -d "$ctex_kit/ctex/test/testfiles" ]; then
  ctex_kit="$root/build/ctex-kit"
  rm -rf "$ctex_kit"
  echo "== cloning ctex-kit at ctex-v2.6.5 =="
  git clone --depth 1 --branch ctex-v2.6.5 \
    https://github.com/CTeX-org/ctex-kit.git "$ctex_kit"
fi

run="$root/build/ctex-subset-run"
rm -rf "$run"
mkdir -p "$run"

cp build/unpacked/*.sty "$run/"
cp build/unpacked/ctex-engine-luacjk.def "$run/"
cp build/unpacked/*.lua "$run/"
cp "$ctex_kit"/ctex/test/support/* "$run/"
# The test tree of ctex brings its own ctexopts.cfg (it selects a fontset);
# append the engine choice so that both settings apply.
printf '%s\n' '\keys_set:nn { ctex / option } { engine = luacjk }' \
  >> "$run/ctexopts.cfg"

tests="
basic01 basic02 basic03 basic04 basic05
autoindent01 autoindent02
cjkfamily-default01 cjkfamily-default02
ccwd-selectfont01 ccwd-zihao01
punct
ecglue01
ccglue03
ctex-package01 ctex-version01
encoding01 engine-detect01
fontswitch01
fonts01 fonts02
"

failed=0
total=0
cd "$run"
for name in $tests; do
  total=$((total + 1))
  cp "$ctex_kit/ctex/test/testfiles/$name.lvt" .
  echo "== $name =="
  if ! lualatex -interaction=nonstopmode -halt-on-error \
       "$name.lvt" >"$name.out" 2>&1; then
    echo "compilation failed: $name" >&2
    tail -40 "$name.out" >&2 || true
    failed=$((failed + 1))
    continue
  fi
  if grep -q '^!' "$name.log"; then
    echo "TeX error in $name:" >&2
    grep '^!' "$name.log" >&2 || true
    failed=$((failed + 1))
    continue
  fi
  if grep -q 'Fatal error occurred' "$name.log"; then
    echo "fatal error in $name:" >&2
    grep 'Fatal error occurred' "$name.log" >&2 || true
    failed=$((failed + 1))
  fi
done

echo "== verifying the backend =="
# Not one of the tests may fall back to LuaTeX-ja.
if grep -l 'luatexja' ./*.log >/dev/null 2>&1; then
  echo "LuaTeX-ja was loaded; the LuaCJK engine file was not used" >&2
  grep -l 'luatexja' ./*.log >&2
  exit 1
fi
grep -q 'ctex-engine-luacjk.def' basic01.log

echo "== verifying ctex option plumbing =="
# ecglue01: \ctexset{experiment/CJKecglue=...} must reach the LuaCJK skip.
grep -q '5.0pt plus 2.0pt minus 1.0pt' ecglue01.log
# ccglue03: a user-set kanjiskip survives \selectfont and \zihao.
grep -q 'user-set-before=\[10.0pt plus 1.0pt minus 1.0pt\]' ccglue03.log
grep -q 'user-set-after-selectfont=\[10.0pt plus 1.0pt minus 1.0pt\]' ccglue03.log
grep -q 'user-set-after-zihao=\[10.0pt plus 1.0pt minus 1.0pt\]' ccglue03.log

echo "ctex subset: $((total - failed))/$total passed"
[ "$failed" -eq 0 ]
