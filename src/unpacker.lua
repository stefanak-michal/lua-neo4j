local unpacker = {}

local msg, offset

function unpacker.unpack(message)
  msg = message
  offset = 1
  
  --print(msg)
  
  return u()
end

function next(length)
  local output = string.sub(msg, offset, offset + length - 1)
  offset = offset + #output
  return output
end

function u()
  local marker = string.byte(next(1))
  
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
    local i, _ = string.unpack('>b', next(1))
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
    length, _ = string.unpack('>B', next(1))
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
    length, _ = string.unpack('>B', next(1))
  elseif marker == 0xD5 then
    length, _ = string.unpack('>H', next(2))
  elseif marker == 0xD6 then
    length, _ = string.unpack('>L', next(4))
  else
    return nil
  end
  
  local output = {}
  while table.len(output) < length do
    output.insert(u())
  end
  
  return output
end

function unpackDictionary(marker)
  local length
  if marker >> 4 == 0xA then
    length = marker - 0xA0
  elseif marker == 0xD8 then
    length, _ = string.unpack('>B', next(1))
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
    size, _ = string.unpack('>B', next(1))
  elseif marker == 0xDD then
    size, _ = string.unpack('>H', next(2))
  else
    return nil
  end
  
  return string.byte(next(1)), u()
  
  --todo specific structures
end

return unpacker
