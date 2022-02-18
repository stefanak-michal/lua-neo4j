local unpacker = {}
local structures = require('structures')
local msg, offset

function unpacker.unpack(message)
  msg = message
  offset = 1
  
  --print(msg)
  
  return u()
end

function next(length)
  length = length or 1
  local output = string.sub(msg, offset, offset + length - 1)
  --print(msg, ' ', offset, length, output, #output)
  --print()
  offset = offset + string.len(output)
  return output
end

function u()
  local marker, _ = string.unpack('>B', next())
  
  if marker == 0xC3 then
    return true
  elseif marker == 0xC2 then
    return false
  elseif marker == 0xC0 then
    return nil
  end

  local value
  
  value = unpackInteger(marker)
  if value ~= nil then
    return value
  end
  
  value = unpackFloat(marker)
  if value ~= nil then
    return value
  end
  
  value = unpackString(marker)
  if value ~= nil then
    return value
  end
  
  value = unpackList(marker)
  if value ~= nil then
    return value
  end
  
  value = unpackDictionary(marker)
  if value ~= nil then
    return value
  end
  
  local signature
  signature, value = unpackStructure(marker)
  if value ~= nil then
    return signature, value
  end
  
  return nil
end

function unpackInteger(marker)
  if marker >> 7 == 0 then
    return marker
  elseif marker >> 4 == 0xF0 then
    local i, _ = string.unpack('>b', string.char(marker))
    return math.tointeger(i)
  elseif marker == 0xC8 then
    local i, _ = string.unpack('>b', next())
    return math.tointeger(i)
  elseif marker == 0xC9 then
    local i, _ = string.unpack('>h', next(2))
    return math.tointeger(i)
  elseif marker == 0xCA then
    local i, _ = string.unpack('>l', next(4))
    return math.tointeger(i)
  elseif marker == 0xCB then
    local i, _ = string.unpack('>i64', next(8))
    return math.tointeger(i)
  else
    return nil
  end
end

function unpackFloat(marker)
  if marker == 0xC1 then
    local f, _ = string.unpack('>d', next(8))
    return tonumber(f)
  else
    return nil
  end
end

function unpackString(marker)
  local length
  if marker >> 4 == 0x8 then
    length = marker - 0x80
  elseif marker == 0xD0 then
    length, _ = string.unpack('>B', next())
  elseif marker == 0xD1 then
    length, _ = string.unpack('>H', next(2))
  elseif marker == 0xD2 then
    length, _ = string.unpack('>L', next(4))
  else
    return nil
  end
  
  return next(length)
end

function unpackList(marker)
  local length
  if marker >> 4 == 0x9 then
    length = marker - 0x90
  elseif marker == 0xD4 then
    length, _ = string.unpack('>B', next())
  elseif marker == 0xD5 then
    length, _ = string.unpack('>H', next(2))
  elseif marker == 0xD6 then
    length, _ = string.unpack('>L', next(4))
  else
    return nil
  end
  
  local output = {}
  while table.len(output) < length do
    table.insert(output, u())
  end
  
  return output
end

function unpackDictionary(marker)
  local length
  if marker >> 4 == 0xA then
    length = marker - 0xA0
  elseif marker == 0xD8 then
    length, _ = string.unpack('>B', next())
  elseif marker == 0xD9 then
    length, _ = string.unpack('>H', next(2))
  elseif marker == 0xDA then
    length, _ = string.unpack('>L', next(4))
  else
    return nil
  end
  
  local output = {}
  while table.len(output) < length do
    output[u()] = u()
  end
  
  return output
end

function unpackStructure(marker)
  local size
  if marker >> 4 == 0xB then
    size = marker - 0xB0
  elseif marker == 0xDC then
    size, _ = string.unpack('>B', next())
  elseif marker == 0xDD then
    size, _ = string.unpack('>H', next(2))
  else
    return nil
  end
  
  local signature, _ = string.unpack('>B', next())
  local structure = structures.bySignature(signature)
  if structure ~= nil then
    local output = {['neotype'] = structure.neotype}
    for i = 1, #structure.keys, 1 do
      local m, _ = string.unpack('>B', next())
      output[structure.keys[i]] = _G['unpack' .. structure.types[i]](m)
    end
    return output
  else
    return signature, u()
  end
end

return unpacker
