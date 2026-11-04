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

# A count is written as a word in the guide ("Ten attributes"), so the check
# reads the word and compares numbers.
num_of() {
  case "$(printf '%s' "$1" | tr 'A-Z' 'a-z')" in
    [0-9]*)  printf '%s\n' "$1" ;;
    one)     echo 1 ;;
    two)     echo 2 ;;
    three)   echo 3 ;;
    four)    echo 4 ;;
    five)    echo 5 ;;
    six)     echo 6 ;;
    seven)   echo 7 ;;
    eight)   echo 8 ;;
    nine)    echo 9 ;;
    ten)     echo 10 ;;
    eleven)  echo 11 ;;
    twelve)  echo 12 ;;
    thirteen) echo 13 ;;
    fourteen) echo 14 ;;
    fifteen) echo 15 ;;
    sixteen) echo 16 ;;
    seventeen) echo 17 ;;
    eighteen) echo 18 ;;
    nineteen) echo 19 ;;
    twenty)  echo 20 ;;
  esac
}

state_number() {
  local label="$1" actual="$2" word="$3" value
  if [ -z "$word" ]; then
    report "$label: the guide no longer states the count"
    return
  fi
  value=$(num_of "$word")
  if [ -z "$value" ]; then
    report "$label: cannot read the number '$word'"
    return
  fi
  [ "$value" = "$actual" ] ||
    report "$label differs" "$dtx: $actual" "guide: $value ($word)"
}

# `tr -d '\r'` keeps the comparison honest when a Windows checkout has CRLF.
depends=$(grep -vE '^\s*(#|$)' DEPENDS.txt | tr -d '\r' | awk '{print $NF}' | sort -u)
tl=$(grep -vE '^\s*(#|$)' .github/tl_packages | tr -d '\r' | sort -u)
known=$(printf '%s\n%s\n' "$depends" "$tl" | sort -u)

# A `\RequirePackage` name and the TeX Live package that installs it are the
# same word for most dependencies, but `expl3` lives in `l3kernel` and
# `l3draw` in `l3experimental`.  The mapping is read from the local
# installation instead of being written here; `DEPENDS.txt` and the package
# list name TeX Live packages, so a name that appears verbatim in either is
# its own answer and needs no lookup.
alias_of() {
  case "$1" in
    expl3)  echo l3kernel ;;
    l3draw) echo l3experimental ;;
    *)      echo "$1" ;;
  esac
}

tlmgr_ok=no
if command -v tlmgr >/dev/null 2>&1 && tlmgr --version >/dev/null 2>&1; then
  tlmgr_ok=yes
fi

tl_cache=$(mktemp) || exit 2
trap 'rm -f "$tl_cache"' EXIT

lookup_bundle() {
  local pkg="$1" cached bundle=""
  cached=$(awk -F'\t' -v p="$pkg" '$1 == p { print $2; exit }' "$tl_cache")
  if [ -n "$cached" ]; then
    printf '%s\n' "$cached"
    return
  fi
  if printf '%s\n' "$known" | grep -qx "$pkg"; then
    bundle="$pkg"
  elif [ "$tlmgr_ok" = yes ]; then
    # Anchor on the file name: `tlmgr` matches the pattern anywhere in the
    # path, so a bare `expl3.sty` also finds `blx-case-expl3.sty`.
    bundle=$(tlmgr search --global --file "^texmf-dist/.*/$pkg\.sty$" 2>/dev/null |
               sed -n 's/^\([A-Za-z0-9._-]*\):$/\1/p' | head -1)
  fi
  [ -n "$bundle" ] || bundle=$(alias_of "$pkg")
  printf '%s\t%s\n' "$pkg" "$bundle" >> "$tl_cache"
  printf '%s\n' "$bundle"
}

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
# A package loaded from the listings guard belongs to an optional output, so
# DEPENDS.txt must mark it `soft`; everything else is `hard`.
requires=$(awk '
  /^%<\*listings>/ { soft = 1 }
  /^%<\/listings>/ { soft = 0 }
  match($0, /\\RequirePackage *\{ *[a-zA-Z0-9-]+ *\}/) {
    s = substr($0, RSTART, RLENGTH)
    sub(/.*\{ */, "", s); sub(/ *\}.*/, "", s)
    if (s !~ /^LuaCJK/) print (soft ? "soft" : "hard"), s
  }' "$dtx" | sort -u)
while read -r class pkg; do
  [ -n "$pkg" ] || continue
  bundle=$(lookup_bundle "$pkg")
  { grep -qx "$class $pkg" DEPENDS.txt ||
    grep -qx "$class $bundle" DEPENDS.txt; } ||
    report "$pkg (bundle $bundle) is required but not listed as $class in DEPENDS.txt"
done <<EOF
$requires
EOF

# --- 6. DEPENDS.txt against .github/tl_packages ---------------------------
while read -r pkg; do
  [ -n "$pkg" ] || continue
  bundle=$(lookup_bundle "$pkg")
  printf '%s\n' "$tl" | grep -qx "$bundle" ||
    report "$pkg (bundle $bundle) is missing from .github/tl_packages"
done <<EOF
$depends
EOF

# --- 7. the ctex subset count ---------------------------------------------
subset=$(sed -n '/^tests="/,/^"/p' scripts/ctex-subset.sh |
           tr -d '"' | tr '\n' ' ' | sed 's/^tests=//' | wc -w | tr -d ' ')
for n in $(grep -oE 'ctex subset: [0-9]+/[0-9]+' "$guide" "$skill" |
             sed 's|.*: ||' | cut -d/ -f1 | sort -u); do
  [ "$n" = "$subset" ] ||
    report "ctex subset count differs" "scripts/ctex-subset.sh: $subset" \
           "guide: $n"
done

# --- 8. the numbers the skill states --------------------------------------
# The sentences are searched on one line, because a count may be split across
# a line break in the source.
skill_flat=$(tr -d '\r' < "$skill" | tr '\n' ' ')
attrs=$(grep -c '\\newattribute ' "$dtx")
decorations=$(grep -cE '^\\NewDocumentCommand \\CJK(underline|sout|underdblline|underwave|xout|underanyline|underanysymbol|underdot)' "$dtx")
options=$(awk '
  /\\keys_define:nn \{ LuaCJKfntef \/ (underline|decoration) \}/ { inside = 1; next }
  inside && /^  \}/ { inside = 0 }
  inside && /^    [a-z]+ \./ { print $1 }' "$dtx" |
  sort -u | grep -vx unknown | wc -l | tr -d ' ')

word_attrs=$(printf '%s' "$skill_flat" |
               grep -oE '[A-Za-z0-9]+ attributes carry' | head -1 | cut -d' ' -f1)
word_decor=$(printf '%s' "$skill_flat" |
               grep -oE '[A-Za-z0-9]+ decorations in `LuaCJKfntef`' |
               head -1 | cut -d' ' -f1)
word_opt=$(printf '%s' "$skill_flat" |
             grep -oE 'with [A-Za-z0-9]+ options' | head -1 | cut -d' ' -f2)

state_number "attribute count" "$attrs" "$word_attrs"
state_number "decoration count" "$decorations" "$word_decor"
state_number "decoration option count" "$options" "$word_opt"

if [ "$fail" -eq 0 ]; then
  echo "OK: the guides agree with the sources"
  exit 0
fi
printf '%d problem(s)\n' "$fail"
exit 1
