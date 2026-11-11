--[==========================================================================[--
    L3BUILD FILE FOR LUACJK                       Copyright (C) by Mingyu Xia
--]==========================================================================]--

--[==========================================================================[--
    Basic Information: Do Check Before Push
--]==========================================================================]--
module              = "luacjk"
local pkg           = "LuaCJK"
version             = "v0.0.1"
date                = "2026-11-11"
maintainer          = "Mingyu Xia"
uploader            = "Mingyu Xia"
maintainid          = "myhsia"
email               = "myhsia@outlook.com"
repository          = "https://github.com/" .. maintainid .. "/" .. pkg
summary             = "A LuaTeX CJK typesetting package"
description         = "LuaCJK provides Chinese typesetting for the LuaTeX engine."

--[==========================================================================[--
    Configuration: Check, Tag, Pack, Upload      Do NOT Modify if Unnecessary
--]==========================================================================]--
packtdszip          = true
sourcefiles         = {pkg .. ".dtx", pkg .. ".ins"}
unpackfiles         = {pkg .. ".ins"}
installfiles        = {"*.sty", "*.lua", "*.def"}
typesetfiles        = {pkg .. ".dtx"}
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
  "*.log", "*.pdf", "*.zip", "*.curlopt", "*.codemo.vrb", "*.out",
  "*.aux", "*.toc", "*.idx", "*.ind", "*.glo", "*.gls", "*.glg",
  "*.hd",  "*.fls", "*.fdb_latexmk",  "*.synctex.gz"
}
excludefiles        = {"*~"}
textfiles           = {"README.md", "LICENSE"}
local tdsname = module
tdslocations        = {
  "tex/latex/"  .. tdsname .. "/" .. pkg .. ".sty",
  "tex/latex/"  .. tdsname .. "/" .. pkg .. "fntef.sty",
  "tex/latex/"  .. tdsname .. "/" .. pkg .. "-listings.sty",
  "tex/latex/"  .. tdsname .. "/ctex-engine-luacjk.def",
  "tex/luatex/" .. tdsname .. "/" .. pkg .. ".lua",
  "tex/luatex/" .. tdsname .. "/" .. pkg .. "-core.lua",
  "tex/luatex/" .. tdsname .. "/" .. pkg .. "fntef.lua"
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
changelog_repo = maintainid .. "/" .. pkg

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
  if not content:match("^## %[" .. pkg .. "%-v%d+%.%d+%.%d+%]%(") then
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

--[==========================================================================[--
    UPLOAD: the CTAN form, one entry per field
--]==========================================================================]--
-- The CTAN package id is `module`: lower case only, and it has to be the name
-- of the top directory of the archive, so `pkg` is not the package spelling.
-- `version` drops the tag's leading `v`, which CTAN would otherwise print.
-- `update` is false for a first release; a later one flips it to true.
uploadconfig        = {
  pkg          = module,
  version      = (version:gsub("^v", "")),
  author       = maintainer,
  uploader     = uploader,
  email        = email,
  summary      = summary,
  description  = description,
  license      = "lppl1.3c",
  ctanPath     = "/macros/luatex/latex/" .. module,
  repository   = repository,
  home         = repository,
  support      = repository .. "/issues",
  bugtracker   = repository .. "/issues",
  development  = repository,
  topic        = {"chinese", "luatex"},
  update       = false,
  note         = "The package ships three Lua modules in tex/luatex/luacjk/ " ..
                 "and a ctex engine file, so this upload carries a TDS-ready " ..
                 "archive beside the package directory. It is there to make " ..
                 "installation and the TeX Live import straightforward; if " ..
                 "the unpacked tree is all you need, please drop the .tds.zip " ..
                 "without hesitation. LuaCJK is meant to run in parallel with " ..
                 "xeCJK and is selected by ctex's engine = luacjk option.",
  announcement = "LuaCJK 0.0.1: Chinese typesetting with LuaTeX\n" ..
                 "\n" ..
                 "LuaCJK is a new package for Chinese typesetting with the " ..
                 "LuaTeX engine, built on node callbacks as xeCJK is built on " ..
                 "XeTeX's interchar tokens. It provides a CJK font family " ..
                 "interface, CJK/CJK and CJK/Latin spacing, the six xeCJK " ..
                 "punctuation styles with their line-breaking prohibitions, " ..
                 "fallback fonts, and a per-node snapshot of every setting, so " ..
                 "a group still decides how the text it sets is typeset. " ..
                 "LuaCJKfntef adds underlining, emphasis dots and " ..
                 "strike-through on top of lua-ul, and LuaCJK-listings keeps " ..
                 "CJK text two columns wide inside a listings block. ctex " ..
                 "selects the backend with the option engine = luacjk.\n"
}
