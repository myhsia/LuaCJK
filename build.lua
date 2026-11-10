--[==========================================================================[--
    L3BUILD FILE FOR LUACJK                       Copyright (C) by Mingyu Xia
--]==========================================================================]--

--[==========================================================================[--
    Basic Information: Do Check Before Push
--]==========================================================================]--
module              = "LuaCJK"
version             = "v0.0.1"
date                = "2026-11-11"
maintainer          = "Mingyu Xia"
uploader            = "Mingyu Xia"
maintainid          = "myhsia"
email               = "myhsia@outlook.com"
repository          = "https://github.com/" .. maintainid .. "/" .. module
summary             = "A LuaTeX CJK typesetting package"
description         = "LuaCJK provides Chinese typesetting for the LuaTeX engine."

--[==========================================================================[--
    Configuration: Check, Tag, Pack, Upload      Do NOT Modify if Unnecessary
--]==========================================================================]--
packtdszip          = true
sourcefiles         = {module .. ".dtx", module .. ".ins"}
unpackfiles         = {module .. ".ins"}
installfiles        = {"*.sty", "*.lua", "*.def"}
typesetfiles        = {module .. ".dtx"}
testfiledir         = "./testfiles"
testsuppdir         = "./testsupport"
testdir             = "./build/check"
checkengines        = {"luatex"}
stdengine           = "luatex"
checkruns           = 2
typesetexe          = "latexmk -pdflua"
typesetruns         = 1
typesetwarnings     = false
cleanfiles          = {
  "*.log", "*.pdf", "*.zip", "*.codemo.vrb", "*.out",
  "*.aux", "*.toc", "*.idx", "*.ind", "*.glo", "*.gls", "*.glg",
  "*.hd", "*.fls", "*.fdb_latexmk", "*.synctex.gz"
}
excludefiles        = {"*~"}
textfiles           = {"README.md", "LICENSE"}
-- The TDS tree is lowercase although the CTAN name is not, so every
-- installed file is named here: the default directory comes from `module'.
local tdsdir = "luacjk"
tdslocations        = {
  "tex/latex/" .. tdsdir .. "/" .. module .. ".sty",
  "tex/latex/" .. tdsdir .. "/" .. module .. "fntef.sty",
  "tex/latex/" .. tdsdir .. "/" .. module .. "-listings.sty",
  "tex/latex/" .. tdsdir .. "/ctex-engine-luacjk.def",
  "tex/luatex/" .. tdsdir .. "/" .. module .. ".lua",
  "tex/luatex/" .. tdsdir .. "/" .. module .. "-core.lua",
  "tex/luatex/" .. tdsdir .. "/" .. module .. "fntef.lua"
}

--[================== "Hacks" to `l3build` | Do not Modify ==================]--
function update_tag(file, content, tagname, tagdate)
  tagname = version
  tagdate = date
  if string.match(file, "%.dtx$") then
    content = string.gsub(content,
      "(\\GetIdInfo%s+%$Id:%s+[^%s]+%.dtx%s+)[^%$]*(%$)",
      "%1" .. tagname .. " " .. tagdate .. " " ..
        maintainid .. "<" .. email .. ">%2")
  end
  return content
end

function docinit_hook()
  cp(ctanreadme, unpackdir, currentdir)
  local path = currentdir .. "/" .. ctanreadme
  local file = assert(io.open(path, "r"))
  local content = file:read("*a")
  file:close()
  file = assert(io.open(path, "w"))
  file:write((content:gsub("%s+$", "")) .. "\n")
  file:close()
  return 0
end

function tex(file,dir,cmd)
  dir = dir or "."
  cmd = cmd or typesetexe
  local glossary_dep =
    "add_cus_dep(q/glo/,q/gls/,0,q/luacjk_glossary/);" ..
    " sub luacjk_glossary" ..
    " { system(qq{makeindex -s " .. glossarystyle ..
    " -o $_[0].gls $_[0].glo}) }"
  if os.getenv("WINDIR") ~= nil or os.getenv("COMSPEC") ~= nil then
    upretex_aux = "-usepretex=\"" .. typesetcmds .. "\""
    makeidx_aux = "-e \"$makeindex=q/makeindex -s " .. indexstyle .. " %O %S/\""
    glossary_aux= "-e \"" .. glossary_dep .. "\""
    sandbox_aux = "set \"TEXINPUTS=../unpacked;%TEXINPUTS%;\" && " ..
                  "set \"LUAINPUTS=../unpacked;%LUAINPUTS%;\" &&"
  else
    upretex_aux = "-usepretex=\'" .. typesetcmds .. "\'"
    makeidx_aux = "-e \'$makeindex=q/makeindex -s " .. indexstyle .. " %O %S/\'"
    glossary_aux= "-e \'" .. glossary_dep .. "\'"
    sandbox_aux = "TEXINPUTS=\"../unpacked:$(kpsewhich -var-value=TEXINPUTS):\" " ..
                  "LUAINPUTS=\"../unpacked:$(kpsewhich -var-value=LUAINPUTS):\""
  end
  return run(dir, sandbox_aux .. " " .. cmd         .. " " ..
                  upretex_aux .. " " .. makeidx_aux .. " " ..
                  glossary_aux .. " " .. file)
end

--[==========================================================================[--
    CHANGELOG: Regenerated from the dtx `\changes` entries
--]==========================================================================]--
changelog_repo = maintainid .. "/" .. module

local extract_changes = dofile("scripts/extract-changes.lua")

local function readfile(path)
  local handle = assert(io.open(path, "rb"))
  local content = handle:read("*a")
  handle:close()
  return content
end

local function changelog(names)
  local errorlevel = extract_changes.main{
    typesetfiles[1], "all", "--repo", changelog_repo, "-o", "CHANGELOG.md" }
  if errorlevel ~= 0 then return errorlevel end
  local content = readfile("CHANGELOG.md")
  for byte = 0, 5 do
    if content:find(string.char(byte), 1, true) then
      print("CHANGELOG.md still contains an extractor placeholder")
      return 1
    end
  end
  if not content:match("^## %[" .. module .. "%-v%d+%.%d+%.%d+%]%(") then
    print("CHANGELOG.md does not start with the release heading")
    return 1
  end
  print("Wrote CHANGELOG.md")
  return 0
end

target_list.changelog =
  {
    desc = "Regenerates CHANGELOG.md from the \\changes entries",
    func = changelog
  }
