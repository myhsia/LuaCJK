#!/usr/bin/env bash
#
# Fail when a regression-test log carries a TeX error.
#
# l3build compares the `.tlg` baseline, and a `.tlg` is the log between the
# `\START` and `\END` markers with the terminal output of a test in it.  A TeX
# error is not part of that comparison: `nonstopmode` skips the undefined token
# and the run continues, so a test passes while its log carries an `! Undefined
# control sequence`, which is how four package options stayed broken unnoticed.
# This script reads every log the last `l3build check` left and reports the
# lines TeX prints for an error.
#
# Three error headlines are expected, because a test provokes them on purpose:
#
#   ! OK.
#       what TeX prints for a successful \showbox, used by decoration01;
#   ! LaTeX Error: The key 'luaul/generic/no-such-key' is unknown ...
#       fntefopts01 asks for an unknown decoration key;
#   ! LaTeX Error: Missing \begin{document}.
#       verb02 and boundary03 build a paragraph in a preamble on purpose.
#
# Everything else is reported, one `file:line:text` record per line.
#
#   bash scripts/check-test-logs.sh            # build/check
#   bash scripts/check-test-logs.sh <dir>      # another build directory
#
# Exit 0 when every log is clean, 1 when something is printed, 2 when the
# directory holds no log (nothing was run, so nothing was judged).

set -u

dir=${1:-build/check}

if [ ! -d "$dir" ]; then
  echo "check-test-logs: $dir does not exist; run l3build check first" >&2
  exit 2
fi

shopt -s nullglob
logs=("$dir"/*.log)
shopt -u nullglob

if [ ${#logs[@]} -eq 0 ]; then
  echo "check-test-logs: $dir holds no log; run l3build check first" >&2
  exit 2
fi

# An error headline that a test provokes on purpose, anchored after the
# `file:line:` prefix grep -Hn writes.
allowed=":(! OK\.\
|! LaTeX Error: The key 'luaul/generic/no-such-key' is unknown and is being ignored\.\
|! LaTeX Error: Missing \\\\begin\\{document\\}\.)$"

bad=$(grep -Hn '^!' "${logs[@]}" | grep -vE "$allowed")

if [ -n "$bad" ]; then
  printf '%s\n' "$bad"
  exit 1
fi

exit 0
