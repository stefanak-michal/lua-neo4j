local fn = {}
local structures = require('structures')
local msg, offset

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
    return nil
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
  
  local signature
  signature, value = fn.Structure(marker)
  if value ~= nil then
    return signature, value
  end
  
  return nil
end

function fn.Integer(marker)
  if marker > 0xF0 and marker < 0x7F then
    return marker
  elseif marker == 0xC8 then
    local i, _ = string.unpack('>b', fn.next())
    return math.tointeger(i)
  elseif marker == 0xC9 then
    local i, _ = string.unpack('>h', fn.next(2))
    return math.tointeger(i)
  elseif marker == 0xCA then
    local i, _ = string.unpack('>l', fn.next(4))
    return math.tointeger(i)
  elseif marker == 0xCB then
    local i, _ = string.unpack('>i64', fn.next(8))
    return math.tointeger(i)
  else
    return nil
  end
end

function fn.Float(marker)
  if marker == 0xC1 then
    local f, _ = string.unpack('>d', fn.next(8))
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
    length, _ = string.unpack('>B', fn.next())
  elseif marker == 0xD1 then
    length, _ = string.unpack('>H', fn.next(2))
  elseif marker == 0xD2 then
    length, _ = string.unpack('>L', fn.next(4))
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
    length, _ = string.unpack('>B', fn.next())
  elseif marker == 0xD5 then
    length, _ = string.unpack('>H', fn.next(2))
  elseif marker == 0xD6 then
    length, _ = string.unpack('>L', fn.next(4))
  else
    return nil
  end
  
  local output = {}
  if length > 0 then
    local i
    for i = 1, length, 1 do
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
    length, _ = string.unpack('>B', fn.next())
  elseif marker == 0xD9 then
    length, _ = string.unpack('>H', fn.next(2))
  elseif marker == 0xDA then
    length, _ = string.unpack('>L', fn.next(4))
  else
    return nil
  end
  
  local output = {}
  if length > 0 then
    local i = 0
    for i = 1, length, 1 do
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
    size, _ = string.unpack('>B', fn.next())
  elseif marker == 0xDD then
    size, _ = string.unpack('>H', fn.next(2))
  else
    return nil
  end
  
  local signature, _ = string.unpack('>B', fn.next())
  local structure = structures.bySignature(signature)
  if structure ~= nil then
    local output = {['neotype'] = structure.neotype}
    for i = 1, #structure.keys, 1 do
      local m, _ = string.unpack('>B', fn.next())
      output[structure.keys[i]] = fn[structure.types[i]](m)
    end
    return output
  else
    return signature, fn.u()
  end
end


local unpacker = {}

function unpacker.unpack(message)
  msg = {}
  for b in string.gmatch(message, '.') do
    table.insert(msg, string.byte(b))
  end
  offset = 1
  return fn.u()
end

return unpacker
