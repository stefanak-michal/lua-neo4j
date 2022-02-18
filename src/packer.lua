local packer = {}
local structures = require('src.structures')
local SMALL, MEDIUM, LARGE, HUGE = 16, 256, 65536, 4294967295

function packer.pack(signature, ...)
  local params = {...}
  local output
  local count = 0
  for _ in pairs(params) do count = count + 1 end

  if count < SMALL then
    output = string.pack('>B', 0xB0 | count)
  elseif count < MEDIUM then
    output = string.char(0xDC) .. string.pack('>B', count)
  elseif count < LARGE then
    output = string.char(0xDD) .. string.pack('>H', count)
  else
    return nil, 'Too many parameters'
  end

  output = output .. string.char(signature)
  
  for i, v in ipairs(params) do
    output = output .. p(v)
  end

  return output
end

function p(param)
  if type(param) == 'number' then
    if math.type(param) == 'integer' then
      return packInteger(param)
    elseif math.type(param) == 'float' then
      return packFloat(param)
    else
      --error
    end
  elseif type(param) == 'string' then
    return packString(param)
  elseif type(param) == 'table' then
    local neotype = param.neotype
    param.neotype = nil
    if neotype == 'list' then
      return packList(param)
    elseif neotype == 'dictionary' then
      return packDictionary(param)
    elseif structures.byType(neotype) ~= nil then
      return packStructure(neotype, param)
    else
      --error
    end
  elseif type(param) == 'boolean' and param == true then
    return string.char(0xC3)
  elseif type(param) == 'boolean' and param == false then
    return string.char(0xC2)
  elseif param == nil then
    return string.char(0xC0)
  else
    --error
  end
end

function packInteger(param)
  if param >= 0 and param <= 127 then
    return string.pack('>B', param)
  elseif param >= -16 and param < 0 then
    return string.pack('>b', 0xF0 | param)
  elseif param >= -128 and param <= -17 then
    return string.char(0xC8) .. string.pack('>b', param)
  elseif ((param >= 128 and param <= 32767) or (param >= -32768 and param <= -129)) then
    return string.char(0xC9) .. string.pack('>h', param)
  elseif ((param >= 32768 and param <= 2147483647) or (param >= -2147483648 and param <= -32769)) then
    return string.char(0xCA) .. string.pack('>l', param)
  elseif ((param >= 2147483648 and param <= 9223372036854775807) or (param >= -9223372036854775808 and param <= -2147483649)) then
    return string.char(0xCB) .. string.pack('>i64', param)
  else
    --error
  end
end

function packFloat(param)
  return string.char(0xC1) .. string.pack('>d', param)
end

function packString(param)
  if #param < SMALL then
    return string.pack('B', 0x80 | #param) .. param
  elseif #param < MEDIUM then
    return string.char(0xD0) .. string.pack('>B', #param) .. param
  elseif #param < LARGE then
    return string.char(0xD1) .. string.pack('>H', #param) .. param
  elseif #param < HUGE then
    return string.char(0xD2) .. string.pack('>L', #param) . param
  else
    --error
  end
end

function packList(param)
  local output
  local count = 0
  for _ in pairs(param) do count = count + 1 end

  if count < SMALL then
    output = string.pack('>B', 0x90 | count)
  elseif count < MEDIUM then
    output = string.char(0xD4) .. string.pack('>B', count)
  elseif count < LARGE then
    output = string.char(0xD5) .. string.pack('>H', count)
  elseif count < HUGE then
    output = string.char(0xD6) .. string.pack('>L', count)
  else
    --error
  end

  for i, v in ipairs(param) do
    output = output .. p(v)
  end

  return output
end

function packDictionary(param)
  local output
  local count = 0
  for _ in pairs(param) do count = count + 1 end

  if count < SMALL then
    output = string.pack('>B', 0xA0 | count)
  elseif count < MEDIUM then
    output = string.char(0xD8) .. string.pack('>B', count)
  elseif count < LARGE then
    output = string.char(0xD9) .. string.pack('>H', count)
  elseif count < HUGE then
    output = string.char(0xDA) .. string.pack('>L', count)
  else
    --error
  end

  for k, v in pairs(param) do
    output = output .. p(tostring(k)) .. p(v)
  end

  return output
end

function packStructure(neotype, param)
  local structure = structures.byType(neotype)
  local output = string.pack('>B', 0xB0 | (table.len(structure) - 2)) .. string.char(structure.signature)
  for k, v in pairs(structure) do
    if k ~= 'signature' and k ~= 'neotype' then
      output = output .. _G['pack' .. v](param[k])
    end
  end
  return output
end

return packer
