#!/usr/bin/env bash
# Check the facts in AGENTS.md and the skill against the code.
#
#   scripts/check-docs.sh      exit 0 = the guides agree with the sources
#
# Every fact is read from its source of truth (build.lua, the dtx, the test
# directory, the subset script), so this file needs no updating when a number
# in the guide changes; only a new TeX Live bundle name or a new optional
# dependency needs an entry in the two tables below.
set -u
cd "$(dirname "$0")/.." || exit 2

fail=0
report() {
  fail=$((fail + 1))
  printf 'FAIL  %s\n' "$1"
  shift
  for line in "$@"; do printf '        %s\n' "$line"; done
}

guide=AGENTS.md
skill=.opencode/skills/SKILL.md
dtx=LuaCJK.dtx

# A `\RequirePackage` name maps to the TeX Live bundle that installs it.
bundle_of() {
  case "$1" in
    expl3)            echo l3kernel ;;
    l3draw)           echo l3experimental ;;
    *)                echo "$1" ;;
  esac
}

# Dependencies that are optional: a package that only some output needs.
is_optional() { case "$1" in listings) return 0 ;; *) return 1 ;; esac; }

[ -f "$guide" ] || { echo "MISSING: $guide" >&2; exit 2; }
[ -f "$skill" ] || { echo "MISSING: $skill" >&2; exit 2; }

# --- 1. the version in the guide ------------------------------------------
bl_version=$(sed -n 's/^version *= *"\(.*\)"/\1/p' build.lua)
guide_version=$(sed -n 's/.*version `\(v[^`]*\)`.*/\1/p' "$guide" | head -1)
if [ -z "$bl_version" ] || [ -z "$guide_version" ]; then
  report "version not found" "build.lua: '${bl_version:-<none>}'" \
         "$guide: '${guide_version:-<none>}'"
elif [ "$bl_version" != "$guide_version" ]; then
  report "version differs" "build.lua: $bl_version" "$guide: $guide_version"
fi

# --- 2. the number of tests ------------------------------------------------
tests=$(ls testfiles/*.lvt 2>/dev/null | wc -l | tr -d ' ')
for n in $(grep -oE '[0-9]+ regression tests|[0-9]+ tests' "$guide" "$skill" |
             cut -d: -f2 | grep -oE '^[0-9]+' | sort -u); do
  [ "$n" = "$tests" ] ||
    report "test count differs" "testfiles/*.lvt: $tests" "guide: $n"
done

# --- 3. the DocStrip blocks named in the guide -----------------------------
blocks=$(grep -oE '^%<\*[a-z][a-z-]*>' "$dtx" | sed 's/%<\*//; s/>//' |
           awk '!seen[$0]++' | tr '\n' ' ')
guide_blocks=$(sed -n '/DocStrip blocks inside/,/^$/p' "$guide" |
                 tr -d '`' | tr '\n' ' ' |
                 sed 's/.*in file order: //' |
                 sed 's/([^)]*)//g' |
                 sed 's/[.,]/ /g; s/  */ /g; s/ *$//')
[ "$(echo $blocks)" = "$(echo $guide_blocks)" ] ||
  report "DocStrip block list differs" "dtx:   $(echo $blocks)" \
         "guide: $(echo $guide_blocks)"

# --- 4. installfiles against tdslocations ----------------------------------
installed=$(sed -n '/^installfiles *=/p' build.lua |
              grep -oE '"[^"]+"' | tr -d '"' |
              sed 's/^\*//; s/^\.//' | sort)
located=$(awk '/^tdslocations *=/{inside=1}
               inside {print}
               inside && /^}/{inside=0}' build.lua |
            grep -oE '"[^"]+"' | tr -d '"' | sed 's|.*/||' | sort)
installed_ext=$(echo $installed | tr ' ' '\n' | sed 's/.*\.//' | sort -u)
located_ext=$(echo $located | tr ' ' '\n' | sed 's/.*\.//' | sort -u)
if [ "$installed_ext" != "$located_ext" ]; then
  report "installed file types and tdslocations disagree" \
         "installfiles: $(echo $installed_ext)" \
         "tdslocations: $(echo $located_ext)"
fi

# --- 5. runtime \RequirePackage against DEPENDS.txt ------------------------
depends=$(grep -vE '^\s*(#|$)' DEPENDS.txt | awk '{print $NF}' | sort -u)
requires=$(awk '/^%<\*package\|fntef\|listings\|ctex>/{inside=1} inside' "$dtx" |
             grep -oE '\\RequirePackage *\{ *[a-zA-Z0-9-]+ *\}' |
             sed 's/.*{ *//; s/ *}//' |
             grep -vE '^(LuaCJK|LuaCJK-listings)$' | sort -u)
for pkg in $requires; do
  bundle=$(bundle_of "$pkg")
  { printf '%s\n' "$depends" | grep -qx "$pkg" ||
    printf '%s\n' "$depends" | grep -qx "$bundle"; } ||
    report "$pkg (bundle $bundle) is required but missing from DEPENDS.txt"
done

# --- 6. DEPENDS.txt against .github/tl_packages ---------------------------
tl=$(grep -vE '^\s*(#|$)' .github/tl_packages | sort -u)
for pkg in $depends; do
  bundle=$(bundle_of "$pkg")
  printf '%s\n' "$tl" | grep -qx "$bundle" ||
    report "$pkg (bundle $bundle) is missing from .github/tl_packages"
done

# --- 7. the ctex subset count ---------------------------------------------
subset=$(sed -n '/^tests="/,/^"/p' scripts/ctex-subset.sh |
           tr -d '"' | tr '\n' ' ' | sed 's/^tests=//' | wc -w | tr -d ' ')
for n in $(grep -oE 'ctex subset: [0-9]+/[0-9]+' "$guide" "$skill" |
             sed 's|.*: ||' | cut -d/ -f1 | sort -u); do
  [ "$n" = "$subset" ] ||
    report "ctex subset count differs" "scripts/ctex-subset.sh: $subset" \
           "guide: $n"
done

if [ "$fail" -eq 0 ]; then
  echo "OK: the guides agree with the sources"
  exit 0
fi
printf '%d problem(s)\n' "$fail"
exit 1
