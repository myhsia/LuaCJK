#!/usr/bin/env bash
# Compile a small subset of ctex's own .lvt tests with the LuaCJK shadow
# engine.  This is a compilation smoke test: ctex's .tlg baselines are for
# LuaTeX-ja and are deliberately not used here.

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

stage="$root/build/ctex-shadow"
run="$root/build/ctex-subset-run"
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
cp "$ctex_kit"/ctex/test/support/* "$run/"

tests="
basic01 basic02 basic03 basic04 basic05
autoindent01 autoindent02
cjkfamily-default01 cjkfamily-default02
ccwd-selectfont01 ccwd-zihao01
punct
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

echo "ctex subset: $((total - failed))/$total passed"
[ "$failed" -eq 0 ]
