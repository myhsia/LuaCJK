#!/usr/bin/env texlua
--
-- Compare the CJK range table of LuaCJK.dtx with the Unicode scripts.
--
-- The table in the dtx is the policy: which code points LuaCJK sets with the
-- CJK class.  It is not a Unicode property, because the punctuation that CJK
-- text shares with Latin has script Common.  The check therefore only asks
-- one question: is there a code point whose script is Han, Hiragana,
-- Katakana, Bopomofo, or Hangul that the table does not list?
--
-- Usage: texlua scripts/check-charclass.lua [LuaCJK.dtx]
--
-- Exit status: 0 the table covers every CJK-script code point,
--              1 some are missing (they are printed as ranges),
--              2 the check cannot run (no dtx, no Scripts.txt, no table).

local dtx_file = arg[1] or "LuaCJK.dtx"

kpse.set_program_name("luatex")

-- Combining Bopomofo tone marks: they belong to a Bopomofo letter and a glue
-- between the two would break the attachment, so they stay outside the table.
local ALLOWED = {
  { 0x02EA, 0x02EB },
}

local CJK_SCRIPTS = {
  Han = true, Hiragana = true, Katakana = true, Bopomofo = true, Hangul = true,
}

local function die (message)
  io.stderr:write("check-charclass: " .. message .. "\n")
  os.exit(2)
end

local function read_table (path)
  local file = io.open(path, "rb")
  if not file then
    die("cannot open " .. path)
  end
  local source = file:read("*a")
  file:close()
  source = source:gsub("\r\n", "\n")
  local start = source:find("local CJK_RANGES = {\n", 1, true)
  if not start then
    die("no CJK_RANGES table in " .. path)
  end
  local body = source:sub(start)
  local stop = body:find("\n}\n", 1, true)
  if not stop then
    die("the CJK_RANGES table is not closed")
  end
  local ranges = {}
  -- The table aligns its columns, so the gap after the comma varies.
  for first, last in body:sub(1, stop):gmatch("{ 0x(%x+),%s*0x(%x+) }") do
    ranges[#ranges + 1] = { tonumber(first, 16), tonumber(last, 16) }
  end
  if #ranges == 0 then
    die("the CJK_RANGES table is empty")
  end
  return ranges
end

local function covered (c, ranges)
  for i = 1, #ranges do
    if c >= ranges[i][1] and c <= ranges[i][2] then
      return true
    end
  end
  return false
end

local function allowed (c)
  for i = 1, #ALLOWED do
    if c >= ALLOWED[i][1] and c <= ALLOWED[i][2] then
      return true
    end
  end
  return false
end

local function read_scripts ()
  local path = kpse.find_file("Scripts.txt")
  if not path then
    die("cannot find Scripts.txt; install the unicode-data bundle")
  end
  local file = io.open(path, "rb")
  if not file then
    die("cannot open " .. path)
  end
  local data = file:read("*a")
  file:close()
  local entries = {}
  for first, last, script in
    data:gmatch("(%x+)%.%.(%x+)%s*;%s*([%a_]+)") do
    entries[#entries + 1] = { tonumber(first, 16), tonumber(last, 16), script }
  end
  for code, script in data:gmatch("\n(%x+)%s*;%s*([%a_]+)") do
    entries[#entries + 1] = { tonumber(code, 16), tonumber(code, 16), script }
  end
  return entries
end

local function merge (list)
  local out = {}
  for _, c in ipairs(list) do
    if out[#out] and c == out[#out][2] + 1 then
      out[#out][2] = c
    else
      out[#out + 1] = { c, c }
    end
  end
  return out
end

local function hex (n)
  if n < 0x10000 then
    return string.format("U+%04X", n)
  end
  return string.format("U+%05X", n)
end

local ranges = read_table(dtx_file)
local missing = {}
for _, entry in ipairs(read_scripts()) do
  local first, last, script = entry[1], entry[2], entry[3]
  if CJK_SCRIPTS[script] then
    for c = first, last do
      if not covered(c, ranges) and not allowed(c) then
        missing[#missing + 1] = c
      end
    end
  end
end

if #missing == 0 then
  io.write("OK: the CJK range table covers every CJK-script code point\n")
  os.exit(0)
end

table.sort(missing)

local merged = merge(missing)
io.write(string.format(
  "MISSING: %d code point(s) in %d range(s) have a CJK script but are not in\n"
  .. "the CJK range table of %s:\n", #missing, #merged, dtx_file))
for i = 1, math.min(#merged, 20) do
  io.write(string.format("  { 0x%04X, 0x%04X },\n", merged[i][1], merged[i][2]))
end
if #merged > 20 then
  io.write(string.format("  ... and %d more\n", #merged - 20))
end
os.exit(1)
