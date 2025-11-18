-- Minimal JSON decoder (from rxi/json.lua, MIT License)
local json = { _version = "0.1.2" }

local decode
local function decode_error(str, idx, msg)
  error(string.format("Error while parsing JSON at position %d: %s", idx, msg))
end

local function codepoint_to_utf8(n)
  local f = math.floor
  if n <= 0x7f then
    return string.char(n)
  elseif n <= 0x7ff then
    return string.char(f(n / 64) + 192, n % 64 + 128)
  elseif n <= 0xffff then
    return string.char(f(n / 4096) + 224, f(n % 4096 / 64) + 128, n % 64 + 128)
  else
    return string.char(f(n / 262144) + 240, f(n % 262144 / 4096) + 128, f(n % 4096 / 64) + 128, n % 64 + 128)
  end
end

local function parse_unicode_escape(s)
  local n1 = tonumber(s:sub(1, 4), 16)
  local n2 = tonumber(s:sub(7, 10), 16)
  if n2 then
    return codepoint_to_utf8((n1 - 0xD800) * 0x400 + (n2 - 0xDC00) + 0x10000)
  end
  return codepoint_to_utf8(n1)
end

local function parse_string(str, i)
  local res = {}
  local j = i + 1
  local k = j

  while j <= #str do
    local x = str:byte(j)

    if x < 32 then
      decode_error(str, j, "control character in string")
    elseif x == 92 then
      table.insert(res, str:sub(k, j - 1))
      j = j + 1
      local c = str:byte(j)
      if c == 34 or c == 92 or c == 47 then
        table.insert(res, string.char(c))
      elseif c == 98 then
        table.insert(res, "\b")
      elseif c == 102 then
        table.insert(res, "\f")
      elseif c == 110 then
        table.insert(res, "\n")
      elseif c == 114 then
        table.insert(res, "\r")
      elseif c == 116 then
        table.insert(res, "\t")
      elseif c == 117 then
        local hex = str:sub(j + 1, j + 4)
        if not hex:find("^%x%x%x%x") then
          decode_error(str, j, "invalid unicode escape in string")
        end
        local u = hex
        j = j + 4
        if str:sub(j + 1, j + 2) == "\\u" then
          local next_hex = str:sub(j + 3, j + 6)
          if next_hex:find("^d[89ab]") then
            u = u .. str:sub(j + 1, j + 6)
            j = j + 6
          end
        end
        table.insert(res, parse_unicode_escape(u))
      else
        decode_error(str, j, "invalid escape char '" .. string.char(c) .. "' in string")
      end
      k = j + 1
    elseif x == 34 then
      table.insert(res, str:sub(k, j - 1))
      return table.concat(res), j + 1
    end

    j = j + 1
  end

  decode_error(str, i, "expected closing quote for string")
end

local function skip_whitespace(str, i)
  local _, j = str:find("^[ \n\r\t]+", i)
  if j then
    return j + 1
  end
  return i
end

local function parse_literal(str, i)
  if str:sub(i, i + 3) == "true" then
    return true, i + 4
  elseif str:sub(i, i + 4) == "false" then
    return false, i + 5
  elseif str:sub(i, i + 3) == "null" then
    return nil, i + 4
  end
  decode_error(str, i, "invalid literal")
end

local function parse_number(str, i)
  local x = i
  x = str:match("^%-?%d+%.?%d*[eE]?[+%-]?%d*", i)
  if not x then
    decode_error(str, i, "invalid number")
  end
  local num = tonumber(x)
  if not num then
    decode_error(str, i, "invalid number")
  end
  return num, i + #x
end

local function parse_array(str, i)
  local res = {}
  i = i + 1
  i = skip_whitespace(str, i)
  if str:sub(i, i) == "]" then
    return res, i + 1
  end
  while true do
    local val
    val, i = decode(str, i)
    table.insert(res, val)
    i = skip_whitespace(str, i)
    local char = str:sub(i, i)
    if char == "]" then
      return res, i + 1
    elseif char ~= "," then
      decode_error(str, i, "expected ']' or ',' in array")
    end
    i = skip_whitespace(str, i + 1)
  end
end

local function parse_object(str, i)
  local res = {}
  i = i + 1
  i = skip_whitespace(str, i)
  if str:sub(i, i) == "}" then
    return res, i + 1
  end
  while true do
    local key
    key, i = decode(str, i)
    if type(key) ~= "string" then
      decode_error(str, i, "expected string for object key")
    end
    i = skip_whitespace(str, i)
    if str:sub(i, i) ~= ":" then
      decode_error(str, i, "expected ':' after object key")
    end
    i = skip_whitespace(str, i + 1)
    local val
    val, i = decode(str, i)
    res[key] = val
    i = skip_whitespace(str, i)
    local char = str:sub(i, i)
    if char == "}" then
      return res, i + 1
    elseif char ~= "," then
      decode_error(str, i, "expected '}' or ',' in object")
    end
    i = skip_whitespace(str, i + 1)
  end
end

decode = function(str, idx)
  idx = skip_whitespace(str, idx or 1)
  local char = str:sub(idx, idx)
  if char == "{" then
    return parse_object(str, idx)
  elseif char == "[" then
    return parse_array(str, idx)
  elseif char == "\"" then
    return parse_string(str, idx)
  elseif char == "-" or char:match("%d") then
    return parse_number(str, idx)
  else
    return parse_literal(str, idx)
  end
end

function json.decode(str)
  if type(str) ~= "string" then
    error("Expected argument of type string for json.decode")
  end
  local res, idx = decode(str, 1)
  idx = skip_whitespace(str, idx)
  if idx <= #str then
    decode_error(str, idx, "trailing garbage")
  end
  return res
end

return json
