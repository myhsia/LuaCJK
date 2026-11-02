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
sourcefiles         = {"luacjk.dtx", "luacjk.ins", "luacjk.tex"}
unpackfiles         = {"luacjk.ins"}
installfiles        = {"*.sty", "*.lua"}
typesetfiles        = {"luacjk.tex"}
testfiledir         = "./testfiles"
testsuppdir         = "./testsupport"
testdir             = "./build/check"
checkengines        = {"luatex"}
stdengine           = "luatex"
checkruns           = 2
typesetexe          = "lualatex"
typesetruns         = 3
typesetwarnings     = false
cleanfiles          = {
  "*.log", "*.pdf", "*.zip", "*.codemo.vrb", "*.out",
  "*.aux", "*.toc", "*.idx", "*.ind", "*.glo", "*.gls",
  "*.hd", "*.fls", "*.fdb_latexmk", "*.synctex.gz"
}
excludefiles        = {"*~"}
textfiles           = {"README.md", "LICENSE", "*.lua"}

--[================== "Hacks" to `l3build` | Do not Modify ==================]--
function update_tag(file, content, tagname, tagdate)
  tagname = version
  tagdate = date
  if string.match(file, module .. ".dtx$") then
    content = string.gsub(content,
      "(%%<package>\\GetIdInfo%s+%$Id:%s+" .. module .. "%.dtx%s+)[^%$]*(%$)",
      "%1" .. tagname .. " " .. tagdate .. " " ..
        maintainid .. "<" .. email .. ">%2")
  end
  return content
end
