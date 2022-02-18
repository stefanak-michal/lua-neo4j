local fn = {}
local structures = require('structures')
local SMALL, MEDIUM, LARGE, HUGE = 16, 256, 65536, 4294967295

function fn.p(param)
  if type(param) == 'number' then
    if math.type(param) == 'integer' then
      return fn.Integer(param)
    elseif math.type(param) == 'float' then
      return fn.Float(param)
    else
      --error
    end
  elseif type(param) == 'string' then
    return fn.String(param)
  elseif type(param) == 'table' then
    local neotype = param.neotype
    param.neotype = nil
    if neotype == 'list' then
      return fn.List(param)
    elseif neotype == 'dictionary' then
      return fn.Dictionary(param)
    elseif structures.byType(neotype) ~= nil then
      return fn.Structure(neotype, param)
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

function fn.Integer(param)
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

function fn.Float(param)
  return string.char(0xC1) .. string.pack('>d', param)
end

function fn.String(param)
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

function fn.List(param)
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
    output = output .. fn.p(v)
  end

  return output
end

function fn.Dictionary(param)
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
    output = output .. fn.p(tostring(k)) .. fn.p(v)
  end

  return output
end

function fn.Structure(neotype, param)
  local structure = structures.byType(neotype)
  local output = string.pack('>B', 0xB0 | #structure.keys) .. string.char(structure.signature)
  for k, v in pairs(structure) do
    for i = 1, #structure.keys, 1 do
      output = output .. fn[structure.types[i]](param[structure.keys[i]])
    end
  end
  return output
end


local packer = {}

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
    output = output .. fn.p(v)
  end

  return output
end

return packer
