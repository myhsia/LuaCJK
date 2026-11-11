#!/usr/bin/env texlua

--[==========================================================================[--
    CHECK BILINGUAL: the two language versions of the user part
--]==========================================================================]--

-- Usage: texlua scripts/check-bilingual.lua [LuaCJK.dtx]
-- Exit: 0 agree, 1 differ (printed), 2 cannot run.

local dtx_file = arg[1] or "LuaCJK.dtx"

local function die (message)
  io.stderr:write("check-bilingual: " .. message .. "\n")
  os.exit(2)
end

local function read_source (path)
  local file = io.open(path, "rb")
  if not file then
    die("cannot open " .. path)
  end
  local source = file:read("*a")
  file:close()
  return (source:gsub("\r\n", "\n"))
end

-- The documentation parts are the regions between a `% \begin{documentation}`
-- line and the next `% \end{documentation}` line, before the implementation.
local function documentation_blocks (source)
  local blocks = {}
  local current = nil
  for line in (source .. "\n"):gmatch("(.-)\n") do
    if line == "% \\begin{implementation}" then
      break
    elseif line == "% \\begin{documentation}" then
      if current then
        die("a documentation environment is opened twice")
      end
      current = {}
    elseif line == "% \\end{documentation}" then
      if not current then
        die("a documentation environment is closed without being opened")
      end
      blocks[#blocks + 1] = table.concat(current, "\n")
      current = nil
    elseif current then
      current[#current + 1] = line
    end
  end
  if current then
    die("the last documentation environment is not closed")
  end
  if #blocks ~= 2 then
    die(string.format("expected two documentation environments, found %d",
      #blocks))
  end
  return blocks[1], blocks[2]
end

-- Read the balanced brace group that follows a command.
local function read_group (text, pos)
  local start = text:find("[^ \t\n]", pos)
  if not start or text:sub(start, start) ~= "{" then
    return nil, pos
  end
  local depth = 0
  local first = start + 1
  local i = start
  while i <= #text do
    local c = text:sub(i, i)
    if c == "\\" then
      i = i + 2
    elseif c == "{" then
      depth = depth + 1
      i = i + 1
    elseif c == "}" then
      depth = depth - 1
      if depth == 0 then
        return text:sub(first, i - 1), i + 1
      end
      i = i + 1
    else
      i = i + 1
    end
  end
  return nil, pos
end

local function normalize (text)
  return (text:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Commands that name an interface object.  `\meta`, `\oarg` and `\marg` carry
-- parameter names, which stay in English in both parts.
local REFERENCE_COMMANDS = {
  cs = true, keys = true, pkg = true, cls = true, file = true, env = true,
  tn = true, val = true, texttt = true, meta = true, oarg = true, marg = true,
  parg = true,
}

local OBJECT_ENVIRONMENTS = {
  ["function"] = true, environment = true, variable = true,
}

local TITLE_COMMANDS = {
  section = true, subsection = true, subsubsection = true,
}

local function utf8_characters (text)
  local characters = {}
  local i = 1
  while i <= #text do
    local byte = text:byte(i)
    local length = 1
    if byte >= 0xF0 then
      length = 4
    elseif byte >= 0xE0 then
      length = 3
    elseif byte >= 0xC0 then
      length = 2
    end
    characters[#characters + 1] = text:sub(i, i + length - 1)
    i = i + length
  end
  return characters
end

-- A section title is Chinese when it holds a character above the CJK radical
-- block.  A translated title is the only place where a Han character can
-- appear inside the skeleton.
local function is_chinese (text)
  for _, character in ipairs(utf8_characters(text)) do
    local byte = character:byte(1)
    local code
    if #character == 1 then
      code = byte
    elseif #character == 2 then
      code = (byte - 0xC0) * 0x40 + (character:byte(2) - 0x80)
    elseif #character == 3 then
      code = (byte - 0xE0) * 0x1000
        + (character:byte(2) - 0x80) * 0x40
        + (character:byte(3) - 0x80)
    else
      code = (byte - 0xF0) * 0x40000
        + (character:byte(2) - 0x80) * 0x1000
        + (character:byte(3) - 0x80) * 0x40
        + (character:byte(4) - 0x80)
    end
    if code >= 0x2E80 then
      return true
    end
  end
  return false
end

-- Scan one block, filling the ordered structure and the reference multiset.
local function scan (text)
  local structure = {}
  local titles = {}
  local references = {}
  local function structure_event (kind, value)
    structure[#structure + 1] = string.format("\\%s{%s}", kind, value)
  end
  local function reference_event (kind, value)
    local key = string.format("\\%s{%s}", kind, value)
    references[key] = (references[key] or 0) + 1
  end
  local i = 1
  while i <= #text do
    local c = text:sub(i, i)
    if c == "\\" then
      local _, stop, name = text:find("^\\([A-Za-z@]+)", i)
      if name then
        if REFERENCE_COMMANDS[name] then
          local argument, next_pos = read_group(text, stop + 1)
          reference_event(name, argument and normalize(argument) or "")
          i = next_pos
        elseif name == "begin" or name == "end" then
          local environment, next_pos = read_group(text, stop + 1)
          environment = environment and normalize(environment) or ""
          structure_event(name, environment)
          i = next_pos
          if name == "begin" and OBJECT_ENVIRONMENTS[environment] then
            local argument, object_pos = read_group(text, i)
            if argument then
              structure_event("object", normalize(argument))
              i = object_pos
            end
          end
        elseif TITLE_COMMANDS[name] then
          local title, next_pos = read_group(text, stop + 1)
          structure_event(name, "")
          titles[#titles + 1] = title and normalize(title) or ""
          i = next_pos
        elseif name == "item" then
          structure_event(name, "")
          i = stop + 1
        else
          i = stop + 1
        end
      else
        i = i + 1
      end
    elseif c == "|" then
      local close = text:find("|", i + 1, true)
      if close then
        reference_event("code", normalize(text:sub(i + 1, close - 1)))
        i = close + 1
      else
        i = i + 1
      end
    else
      i = i + 1
    end
  end
  return structure, references, titles
end

local function sorted_keys (table_)
  local keys = {}
  for key in pairs(table_) do
    keys[#keys + 1] = key
  end
  table.sort(keys)
  return keys
end

local source = read_source(dtx_file)
local chinese_text, english_text = documentation_blocks(source)
local chinese_structure, chinese_references, chinese_titles =
  scan(chinese_text)
local english_structure, english_references, english_titles =
  scan(english_text)

local problems = {}

-- The Chinese part comes first, and its section titles are the Chinese ones.
local function count_chinese_titles (titles)
  local count = 0
  for _, title in ipairs(titles) do
    if is_chinese(title) then
      count = count + 1
    end
  end
  return count
end

if count_chinese_titles(chinese_titles) == 0 then
  problems[#problems + 1] = "the first documentation part has no Chinese title"
end
if count_chinese_titles(english_titles) > 0 then
  problems[#problems + 1] =
    "the second documentation part has a Chinese title"
end

-- The structure, in order.
local limit = math.max(#chinese_structure, #english_structure)
for index = 1, limit do
  local zh, en = chinese_structure[index], english_structure[index]
  if not zh then
    problems[#problems + 1] = string.format(
      "structure %d: only the English part has %s", index, en)
  elseif not en then
    problems[#problems + 1] = string.format(
      "structure %d: only the Chinese part has %s", index, zh)
  elseif zh ~= en then
    problems[#problems + 1] = string.format(
      "structure %d: Chinese %s, English %s", index, zh, en)
  end
  if #problems >= 20 then
    break
  end
end

-- The references, without their order.
if #problems < 20 then
  local keys = {}
  for _, key in ipairs(sorted_keys(chinese_references)) do
    keys[#keys + 1] = key
  end
  for _, key in ipairs(sorted_keys(english_references)) do
    if not chinese_references[key] then
      keys[#keys + 1] = key
    end
  end
  table.sort(keys)
  for _, key in ipairs(keys) do
    local zh = chinese_references[key] or 0
    local en = english_references[key] or 0
    if zh ~= en then
      problems[#problems + 1] = string.format(
        "reference %s: %d time(s) in Chinese, %d in English", key, zh, en)
    end
    if #problems >= 20 then
      break
    end
  end
end

if #problems == 0 then
  io.write(string.format(
    "OK: the two documentation parts agree (%d structural events, "
    .. "%d distinct references)\n", #chinese_structure,
    #sorted_keys(chinese_references)))
  os.exit(0)
end

io.write(string.format(
  "FAIL: the Chinese and the English documentation differ "
  .. "(%d and %d structural events)\n",
  #chinese_structure, #english_structure))
for _, problem in ipairs(problems) do
  io.write("  " .. problem .. "\n")
end
os.exit(1)
