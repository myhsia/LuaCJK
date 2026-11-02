# ctex test shadow

This directory contains a **test-only** shadow of ctex's LuaTeX engine file.
It is used by `scripts/ctex-shadow.sh` and the `ctex-shadow` CI job to check
that the CTAN/TeX Live version of ctex can load LuaCJK instead of LuaTeX-ja.

It is not part of the LuaCJK package, is not listed in `installfiles`, and
must not be installed into a TeX tree.  The generated
`ctex-engine-luatex.def` lives only under `build/` during a test run.
