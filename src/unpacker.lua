-- https://7687.org/packstream/packstream-specification-1.html

local fn = {} -- Contains private functions for unpacking
local unpacker = {}
local structures = require('structures')
local msg, offset -- Stored message as table of bytes

-- Get next bytes from message
function fn.next(length)
  length = length or 1
  local output = ''
  for i = offset, offset + length - 1, 1 do
    output = output .. string.char(msg[i])
  end
  offset = offset + length
  return output
end

function fn.u()
  local marker = string.byte(fn.next())
  
  if marker == 0xC3 then
    return true
  elseif marker == 0xC2 then
    return false
  elseif marker == 0xC0 then
    return {['neotype'] = 'null'}
  end

  local value
  
  value = fn.Integer(marker)
  if value ~= nil then
    return value
  end
  
  value = fn.Float(marker)
  if value ~= nil then
    return value
  end
  
  value = fn.String(marker)
  if value ~= nil then
    return value
  end
  
  value = fn.List(marker)
  if value ~= nil then
    return value
  end
  
  value = fn.Dictionary(marker)
  if value ~= nil then
    return value
  end
  
  --local signature
  value = fn.Structure(marker)
  if value ~= nil then
    return value
  end
  
  return nil
end

function fn.Integer(marker)
  if marker >> 4 >= 0xF or marker >> 4 <= 0x7 then
    local i = string.unpack('>i1', string.char(marker))
    return math.tointeger(i)
  elseif marker == 0xC8 then
    local i = string.unpack('>i1', fn.next())
    return math.tointeger(i)
  elseif marker == 0xC9 then
    local i = string.unpack('>i2', fn.next(2))
    return math.tointeger(i)
  elseif marker == 0xCA then
    local i = string.unpack('>i4', fn.next(4))
    return math.tointeger(i)
  elseif marker == 0xCB then
    local i = string.unpack('>i8', fn.next(8))
    return math.tointeger(i)
  else
    return nil
  end
end

function fn.Float(marker)
  if marker == 0xC1 then
    local f = string.unpack('>d', fn.next(8))
    return tonumber(f)
  else
    return nil
  end
end

function fn.String(marker)
  local length
  if marker >> 4 == 0x8 then
    length = 0x80 ~ marker
  elseif marker == 0xD0 then
    length = string.unpack('>I1', fn.next())
  elseif marker == 0xD1 then
    length = string.unpack('>I2', fn.next(2))
  elseif marker == 0xD2 then
    length = string.unpack('>I4', fn.next(4))
  else
    return nil
  end
  return fn.next(length)
end

function fn.List(marker)
  local length
  if marker >> 4 == 0x9 then
    length = 0x90 ~ marker
  elseif marker == 0xD4 then
    length = string.unpack('>I1', fn.next())
  elseif marker == 0xD5 then
    length = string.unpack('>I2', fn.next(2))
  elseif marker == 0xD6 then
    length = string.unpack('>I4', fn.next(4))
  else
    return nil
  end
  
  local output = {}
  if length > 0 then
    for _ = 1, length, 1 do
      table.insert(output, fn.u())
    end
  end
  
  return output
end

function fn.Dictionary(marker)
  local length
  if marker >> 4 == 0xA then
    length = 0xA0 ~ marker
  elseif marker == 0xD8 then
    length = string.unpack('>I1', fn.next())
  elseif marker == 0xD9 then
    length = string.unpack('>I2', fn.next(2))
  elseif marker == 0xDA then
    length = string.unpack('>I4', fn.next(4))
  else
    return nil
  end
  
  local output = {}
  if length > 0 then
    for _ = 1, length, 1 do
      output[fn.u()] = fn.u()
    end
  end
  
  return output
end

function fn.Structure(marker)
  local size
  if marker >> 4 == 0xB then
    size = 0xB0 ~ marker
  elseif marker == 0xDC then
    size = string.unpack('>I1', fn.next())
  elseif marker == 0xDD then
    size = string.unpack('>I2', fn.next(2))
  else
    return nil
  end
  
  local signature = string.unpack('>I1', fn.next())
  local structure = structures.bySignature(signature)
  if structure ~= nil then
    local output = {['neotype'] = structure.neotype}
    for i = 1, #structure.keys, 1 do
      local m = string.unpack('>I1', fn.next())
      output[structure.keys[i]] = fn[structure.types[i]](m)
    end
    return output
  else
    unpacker.signature = signature
    return fn.u()
  end
end


-- Public method to unpack message
function unpacker.unpack(message)
  msg = {}
  for b in string.gmatch(message, '.') do
    table.insert(msg, string.byte(b))
  end
  offset = 1
  return fn.u()
end

return unpacker
