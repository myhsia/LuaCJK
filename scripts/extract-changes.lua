--[==========================================================================[--
    EXTRACT CHANGES                          Copyright (C) by Mingyu Xia
--]==========================================================================]--

-- Extract the \changes{v<version>}{<date>}{...} entries of one or more .dtx
-- files and emit the markdown list that becomes CHANGELOG.md.
--
--     texlua scripts/extract-changes.lua <dtx...> all|<version> \
--            [--repo <owner>/<name>] [-o <file>]
--
-- This is a Lua port of ctex-kit's scripts/extract-changes.py, which stays
-- the reference implementation (ctex-kit is LPPL v1.3c, as is this file).
-- The port is verified against the six committed changelogs of ctex-kit:
-- ctex, xeCJK, xpinyin, zhlineskip, zhmetrics and zhnumber reproduce byte
-- for byte, see scripts/check-extract-changes.sh.
--
-- Differences from the Python, all deliberate:
--   * the file names are taken literally, a pattern is not expanded;
--   * only ASCII whitespace is collapsed, which is what the dtx files use;
--   * \keys, \oarg and \marg are understood, so a key is written with the
--     same markup as in the running text: \keys{x} is `x`, \oarg{x} is
--     `[x]`, \marg{x} is `{x}`;
--   * --repo names the forge repository of the release link.
--
-- The output is written by the script itself, UTF-8 and LF, because a shell
-- redirection gives UTF-16LE on Windows PowerShell 5 and that breaks the
-- byte comparison in CI.

local M = {}

local NUL, SOH, STX, ETX, EOT, ENQ =
  string.char(0), string.char(1), string.char(2),
  string.char(3), string.char(4), string.char(5)

-- A markdown inline code span, with a delimiter long enough to hold any
-- backtick run of the content.
local function to_inline_code(s)
  if not s:find("`", 1, true) then return "`" .. s .. "`" end
  local longest = 0
  for run in s:gmatch("`+") do
    if #run > longest then longest = #run end
  end
  local delimiter = string.rep("`", longest + 1)
  local before = s:sub(1, 1) == "`" and " " or ""
  local after = s:sub(-1) == "`" and " " or ""
  return delimiter .. before .. s .. after .. delimiter
end

-- Read the argument of a command: `pos` is the index of its `{`, the return
-- values are the content and the index of the closing `}`.  A backslash
-- protects the character after it, so `\}` does not close the argument.
local function read_arg(s, pos)
  if s:sub(pos, pos) ~= "{" then return nil end
  local out, i, n = {}, pos + 1, #s
  while i <= n do
    local c = s:sub(i, i)
    if c == "\\" and i < n then
      out[#out + 1] = s:sub(i, i + 1)
      i = i + 2
    elseif c == "}" then
      return table.concat(out), i
    else
      out[#out + 1] = c
      i = i + 1
    end
  end
  return nil
end

-- Replace every occurrence of `\name{...}` for the names in `names`, from
-- left to right, by what `func` returns for the argument.
local function replace_cmds(s, names, func)
  local out, i, n = {}, 1, #s
  while i <= n do
    local start, which = nil, nil
    for _, name in ipairs(names) do
      local found = s:find("\\" .. name .. "{", i, true)
      if found and (not start or found < start) then
        start, which = found, name
      end
    end
    if not start then
      out[#out + 1] = s:sub(i)
      break
    end
    local content, close = read_arg(s, start + #which + 1)
    if not content then
      out[#out + 1] = s:sub(i)
      break
    end
    out[#out + 1] = s:sub(i, start - 1)
    out[#out + 1] = func(content)
    i = close + 1
  end
  return table.concat(out)
end

-- The CJK ranges whose surrounding spaces are removed, so that a paragraph
-- of Chinese prose broken over two lines reads as one sentence.
local function is_cjk(cp)
  return (cp >= 0x4E00 and cp <= 0x9FFF)
    or (cp >= 0x3400 and cp <= 0x4DBF)
    or (cp >= 0x3000 and cp <= 0x303F)
    or (cp >= 0xFF00 and cp <= 0xFFEF)
    or cp == 0x2014
    or cp == 0x2026
    or (cp >= 0x20000 and cp <= 0x3FFFF)
end

local function is_space(cp)
  return cp == 0x20 or (cp >= 0x09 and cp <= 0x0D)
end

-- Remove the whitespace between two CJK characters, which the Python does
-- with a lookahead.
local function cjk_join(s)
  local ok, codepoints = pcall(function()
    local list = {}
    for _, cp in utf8.codes(s) do list[#list + 1] = cp end
    return list
  end)
  if not ok then return s end
  local out = {}
  local k, n = 1, #codepoints
  while k <= n do
    local cp = codepoints[k]
    if is_cjk(cp) then
      local j = k + 1
      while j <= n and is_space(codepoints[j]) do j = j + 1 end
      out[#out + 1] = utf8.char(cp)
      k = (j > k + 1 and j <= n and is_cjk(codepoints[j])) and j or k + 1
    else
      out[#out + 1] = utf8.char(cp)
      k = k + 1
    end
  end
  return table.concat(out)
end

-- Save `$...$` before the command cleaning, unwrapping \texttt inside it.
local function save_math(s, blocks)
  local out, i, n = {}, 1, #s
  while i <= n do
    local start = s:find("$", i, true)
    if not start then
      out[#out + 1] = s:sub(i)
      break
    end
    out[#out + 1] = s:sub(i, start - 1)
    local p, close = start + 1, nil
    while p <= n do
      if s:sub(p, p) == "\\" and s:sub(p + 1, p + 1) == "$" then
        p = p + 2
      elseif s:sub(p, p) == "$" then
        close = p
        break
      else
        p = p + 1
      end
    end
    if not close or close == start + 1 then
      out[#out + 1] = "$"
      i = start + 1
    else
      local block = s:sub(start, close)
      block = replace_cmds(block, { "texttt" }, function(arg) return arg end)
      block = block:gsub("\\textbackslash", "\\backslash")
      blocks[#blocks + 1] = block
      out[#out + 1] = STX .. (#blocks - 1) .. ETX
      i = close + 1
    end
  end
  return table.concat(out)
end

-- The content of a saved verbatim or \texttt span: the escapes that protect
-- TeX's special characters are removed, and a \cs inside is restored to a
-- backslash form because it can no longer be recognised after saving.
local function clean_verbatim(content)
  content = content:gsub("\\textbackslash%s*", "\\")
  content = content:gsub("\\([&%%#{}_])", "%1")
  content = content:gsub(NUL .. "([^" .. SOH .. "]*)" .. SOH, "\\%1")
  return content
end

local function save_verbatim(blocks, content)
  blocks[#blocks + 1] = clean_verbatim(content)
  return EOT .. (#blocks - 1) .. ENQ
end

-- Replace the runs of adjacent code and verbatim placeholders by one inline
-- code span, which is what makes `\cs{a}|[b]|` a single code span.
local function restore_code(s, verbatim)
  local out, i, n = {}, 1, #s
  while i <= n do
    local code = s:find(NUL, i, true)
    local verb = s:find(EOT, i, true)
    local start = nil
    if code and (not verb or code < verb) then start = code
    elseif verb then start = verb end
    if not start then
      out[#out + 1] = s:sub(i)
      break
    end
    if start > i then out[#out + 1] = s:sub(i, start - 1) end
    local pieces, p, complete = {}, start, true
    while true do
      local c = s:sub(p, p)
      if c == NUL then
        local close = s:find(SOH, p + 1, true)
        if not close then complete = false break end
        pieces[#pieces + 1] = "\\" .. s:sub(p + 1, close - 1)
        p = close + 1
      elseif c == EOT then
        local close = s:find(ENQ, p + 1, true)
        if not close then complete = false break end
        local index = tonumber(s:sub(p + 1, close - 1)) or 0
        pieces[#pieces + 1] = verbatim[index + 1] or ""
        p = close + 1
      else
        break
      end
    end
    if not complete then
      out[#out + 1] = s:sub(start, start)
      i = start + 1
    else
      out[#out + 1] = to_inline_code(table.concat(pieces))
      i = p
    end
  end
  return table.concat(out)
end

-- The engine names of the prose, longest first so that a prefix does not
-- swallow a longer name.
local engines = {
  "LaTeXiii", "LaTeX3", "XeLaTeX", "LuaLaTeX", "pdfLaTeX", "upLaTeX",
  "ApLaTeX", "pLaTeX", "LaTeXe", "LaTeX", "XeTeX", "LuaTeX", "pdfTeX",
  "upTeX", "ApTeX", "pTeX", "TeX",
}

local engine_text = {
  LaTeXiii = "LaTeX3 ", LaTeX3 = "LaTeX3 ", LaTeXe = "LaTeX2e ",
  XeLaTeX = "XeLaTeX ", LuaLaTeX = "LuaLaTeX ", pdfLaTeX = "pdfLaTeX ",
  upLaTeX = "upLaTeX ", ApLaTeX = "ApLaTeX ", pLaTeX = "pLaTeX ",
  LaTeX = "LaTeX ", XeTeX = "XeTeX ", LuaTeX = "LuaTeX ",
  pdfTeX = "pdfTeX ", upTeX = "upTeX ", ApTeX = "ApTeX ", pTeX = "pTeX ",
  TeX = "TeX ",
}

local function replace_engines(s)
  for _, name in ipairs(engines) do
    s = s:gsub("\\" .. name .. "\\%s", engine_text[name])
    s = s:gsub("\\" .. name .. "{}", engine_text[name])
    s = s:gsub("\\" .. name, engine_text[name])
  end
  return s
end

local function clean(text)
  local math, verbatim = {}, {}
  text = save_math(text, math)
  text = replace_cmds(text, { "cs", "tn" }, function(arg)
    return NUL .. arg .. SOH
  end)
  text = text:gsub("|([^|]+)|", function(content)
    return save_verbatim(verbatim, content)
  end)
  text = text:gsub('"([^"]+)"', function(content)
    return save_verbatim(verbatim, content)
  end)
  text = replace_cmds(text, { "texttt" }, function(content)
    return save_verbatim(verbatim, content)
  end)
  text = replace_cmds(text, { "pkg", "cls", "file", "env" }, to_inline_code)
  text = replace_cmds(text, { "opt", "keys" }, function(content)
    local key, value = content:match("^(.-)!=(.*)$")
    if key then return to_inline_code(key .. " = " .. value) end
    return to_inline_code(content)
  end)
  text = replace_cmds(text, { "oarg" }, function(content)
    return to_inline_code("[" .. content .. "]")
  end)
  text = replace_cmds(text, { "marg" }, function(content)
    return to_inline_code("{" .. content .. "}")
  end)
  text = replace_cmds(text, { "textbf" }, function(content)
    return "**" .. content .. "**"
  end)
  text = text:gsub("\\#", "#")
  text = text:gsub("\\{", "{")
  text = text:gsub("\\}", "}")
  text = replace_engines(text)
  text = text:gsub("\\%a+{}%s*", "")
  text = text:gsub("\\%a+%s*", "")
  text = text:gsub("\\%s", " ")
  text = text:gsub("~", " ")
  text = text:gsub("  +", " ")
  text = text:gsub("^%s+", ""):gsub("%s+$", "")
  text = text:gsub(STX .. "(%d+)" .. ETX, function(index)
    return math[tonumber(index) + 1] or ""
  end)
  text = restore_code(text, verbatim)
  return text
end

-- The \changes entries of one file: a list of {version, text} in file order.
function M.extract(path, target)
  local file = io.open(path, "rb")
  if not file then return nil end
  local content = file:read("*a")
  file:close()
  -- A CRLF checkout must produce the same bytes. The body extraction below
  -- collapses every run of whitespace, so this is a guard rather than the
  -- mechanism, but a pattern that matches a line break must not depend on the
  -- checkout.
  content = content:gsub("\r\n", "\n")

  local lines = {}
  for line in (content .. "\n"):gmatch("(.-)\n") do lines[#lines + 1] = line end
  if #lines > 0 and lines[#lines] == "" and content:sub(-1) == "\n" then
    lines[#lines] = nil
  end

  local version = target:lower()
  local tag = version == "all" and "\\changes{" or "\\changes{" .. target .. "}"
  local entries = {}
  local i = 1
  while i <= #lines do
    local line = lines[i]
    if not line:find(tag, 1, true) then
      i = i + 1
    else
      local text = line
      i = i + 1
      while i <= #lines
        and lines[i]:match("^%%%s+%S")
        and not lines[i]:find("\\changes{", 1, true)
        and not lines[i]:find("\\begin{", 1, true)
      do
        text = text .. " " .. lines[i]:gsub("^[%% ]+", "")
        i = i + 1
      end
      -- \changes{version}{date}{
      local open = text:find("\\changes{", 1, true)
      local name, after = nil, nil
      if open then
        local first = text:find("}", open + 9, true)
        if first then
          name = text:sub(open + 9, first - 1)
          local p = first + 1
          while p <= #text and text:sub(p, p):match("%s") do p = p + 1 end
          if text:sub(p, p) == "{" then
            local second = text:find("}", p + 1, true)
            if second then
              local q = second + 1
              while q <= #text and text:sub(q, q):match("%s") do q = q + 1 end
              if text:sub(q, q) == "{" then after = q + 1 end
            end
          end
        end
      end
      if name and after then
        -- the body runs to the brace that closes the third argument
        local depth, out, j = 1, {}, after
        while j <= #text do
          local c = text:sub(j, j)
          if c == "\\" and j < #text
            and (text:sub(j + 1, j + 1) == "{" or text:sub(j + 1, j + 1) == "}")
          then
            out[#out + 1] = text:sub(j, j + 1)
            j = j + 2
          else
            if c == "{" then
              depth = depth + 1
            elseif c == "}" then
              depth = depth - 1
              if depth == 0 then break end
            end
            out[#out + 1] = c
            j = j + 1
          end
        end
        local body = table.concat(out):gsub("%s+", " ")
        body = body:gsub("^%s+", ""):gsub("%s+$", "")
        body = cjk_join(body)
        body = clean(body)
        if body ~= "" then entries[#entries + 1] = { name, body } end
      end
    end
  end
  return entries
end

-- The stem of a file name, as Python's splitext: the last extension goes,
-- a leading dot does not count as one.
local function basename(path)
  local name = path:match("([^/\\]+)$") or path
  local root = name:match("^(.*)%.[^%.]*$")
  if root and root ~= "" then name = root end
  return name
end

local function commonprefix(a, b)
  local n, i = math.min(#a, #b), 1
  while i <= n and a:sub(i, i) == b:sub(i, i) do i = i + 1 end
  return a:sub(1, i - 1)
end

-- The version order of the Python: split on digit runs, compare the kinds
-- first, newest first.
local function version_key(version)
  local text = version:lower():gsub("^v+", "")
  local parts, pos = {}, 1
  while pos <= #text do
    local first, last = text:find("%d+", pos)
    if not first then
      parts[#parts + 1] = { 1, text:sub(pos) }
      break
    end
    if first > pos then parts[#parts + 1] = { 1, text:sub(pos, first - 1) } end
    parts[#parts + 1] = { 0, tonumber(text:sub(first, last)) }
    pos = last + 1
  end
  return parts
end

local function newer(a, b)
  local ka, kb = version_key(a), version_key(b)
  for i = 1, math.min(#ka, #kb) do
    if ka[i][1] ~= kb[i][1] then return ka[i][1] > kb[i][1] end
    if ka[i][2] ~= kb[i][2] then return ka[i][2] > kb[i][2] end
  end
  return #ka > #kb
end

function M.main(argv)
  local paths, output, repo = {}, nil, "CTeX-org/ctex-kit"
  local i = 1
  while i <= #argv do
    local arg = argv[i]
    if arg == "-o" then
      output = argv[i + 1]
      i = i + 2
    elseif arg == "--repo" then
      repo = argv[i + 1]
      i = i + 2
    else
      paths[#paths + 1] = arg
      i = i + 1
    end
  end
  if #paths < 2 then
    io.stderr:write("usage: extract-changes.lua <dtx...> all|<version>" ..
                    " [--repo <owner>/<name>] [-o <file>]\n")
    return 2
  end
  local target = paths[#paths]
  table.remove(paths, #paths)
  local all = target:lower() == "all"

  -- the common prefix of the file names is the package name
  local names = {}
  for _, path in ipairs(paths) do
    local probe = io.open(path, "rb")
    if probe then
      probe:close()
      names[#names + 1] = basename(path)
    end
  end
  local package = names[1] and names[1] or "package"
  for _, name in ipairs(names) do package = commonprefix(package, name) end
  package = package:gsub("[-_]+$", "")
  if package == "" and names[1] then package = names[1] end

  -- group the entries by version, keeping the order of first appearance
  local groups, order, seen = {}, {}, {}
  for _, path in ipairs(paths) do
    local entries = M.extract(path, target)
    for _, entry in ipairs(entries or {}) do
      local key = entry[1] .. "\0" .. entry[2]
      if not seen[key] then
        seen[key] = true
        if not groups[entry[1]] then
          groups[entry[1]] = {}
          order[#order + 1] = entry[1]
        end
        table.insert(groups[entry[1]], entry[2])
      end
    end
  end

  local versions = {}
  for _, version in ipairs(order) do versions[#versions + 1] = version end
  table.sort(versions, newer)

  local out = {}
  for _, version in ipairs(versions) do
    if all then
      out[#out + 1] = "## [" .. package .. "-" .. version .. "]" ..
                      "(https://github.com/" .. repo .. "/releases/tag/" ..
                      package .. "-" .. version .. ")\n"
    end
    for _, text in ipairs(groups[version]) do
      out[#out + 1] = "- " .. text
    end
    out[#out + 1] = ""
  end
  while #out > 0 and out[#out] == "" do table.remove(out) end
  local result = #out > 0 and (table.concat(out, "\n") .. "\n") or ""

  if output then
    local handle = assert(io.open(output, "wb"))
    handle:write(result)
    handle:close()
  else
    io.write(result)
  end
  return 0
end

-- Run as a script when named on the command line; `dofile` from build.lua
-- gets the table and runs nothing.
if arg and arg[0] and arg[0]:match("extract%-changes%.lua$") then
  os.exit(M.main(arg))
end

return M
