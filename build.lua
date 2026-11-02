--[==========================================================================[--
    L3BUILD FILE FOR LUACJK                       Copyright (C) by Mingyu Xia
--]==========================================================================]--

--[==========================================================================[--
    Basic Information: Do Check Before Push
--]==========================================================================]--
module              = "luacjk"
version             = "0.1.0"
date                = "2026-11-02"
maintainer          = "Mingyu Xia"
uploader            = "Mingyu Xia"
maintainid          = "myhsia"
email               = "myhsia@outlook.com"
repository          = "https://github.com/" .. maintainid .. "/LuaCJK"
summary             = "A LuaTeX CJK typesetting package"
description         = "LuaCJK provides Chinese typesetting for LuaLaTeX, inspired by xeCJK."

--[==========================================================================[--
    Configuration: Check, Tag, Pack, Upload     Do NOT Modify if Unnecessary
--]==========================================================================]--
packtdszip          = true
sourcefiles         = {"LuaCJK.dtx", "LuaCJK.ins"}
unpackfiles         = {"LuaCJK.ins"}
installfiles        = {"*.sty", "*.lua"}
typesetfiles        = {"LuaCJK.dtx"}
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
  "*.aux", "*.toc", "*.idx", "*.ind", "*.glo", "*.gls",
  "*.hd", "*.fls", "*.fdb_latexmk", "*.synctex.gz"
}
excludefiles        = {"*~"}
textfiles           = {"README.md", "LICENSE"}
tdslocations        = {
  "tex/luatex/luacjk/LuaCJK.lua",
  "tex/luatex/luacjk/LuaCJK-core.lua"
}

--[================== "Hacks" to `l3build` | Do not Modify ==================]--
function update_tag(file, content, tagname, tagdate)
  tagname = version
  tagdate = date
  if string.match(file, "LuaCJK.dtx$") then
    content = string.gsub(content,
      "(%%<[a-z]+>\\GetIdInfo%s+%$Id:%s+LuaCJK%.dtx%s+)[^%$]*(%$)",
      "%1" .. tagname .. " " .. tagdate .. " " ..
        maintainid .. "<" .. email .. ">%2")
  end
  return content
end

-- `l3build` normally appends `\input <file>` to `typesetexe`.  `latexmk`
-- expects a file name, so run it on the driver file directly and give it the
-- l3doc index style.  The Windows branch follows `docext`'s build script.
function tex(file,dir,cmd)
  dir = dir or "."
  cmd = cmd or typesetexe
  if os.getenv("WINDIR") ~= nil or os.getenv("COMSPEC") ~= nil then
    upretex_aux = "-usepretex=\"" .. typesetcmds .. "\""
    makeidx_aux = "-e \"$makeindex=q/makeindex -s " .. indexstyle .. " %O %S/\""
    sandbox_aux = "set \"TEXINPUTS=../unpacked;%TEXINPUTS%;\" && " ..
                  "set \"LUAINPUTS=../unpacked;%LUAINPUTS%;\" &&"
  else
    upretex_aux = "-usepretex=\'" .. typesetcmds .. "\'"
    makeidx_aux = "-e \'$makeindex=q/makeindex -s " .. indexstyle .. " %O %S/\'"
    sandbox_aux = "TEXINPUTS=\"../unpacked:$(kpsewhich -var-value=TEXINPUTS):\" " ..
                  "LUAINPUTS=\"../unpacked:$(kpsewhich -var-value=LUAINPUTS):\""
  end
  return run(dir, sandbox_aux .. " " .. cmd         .. " " ..
                  upretex_aux .. " " .. makeidx_aux .. " " .. file)
end
