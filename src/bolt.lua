local bolt = {}

local connection = require('src.connection')
local packer = require('src.packer')
local unpacker = require('src.unpacker')

function table.len(t)
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count
end

-- Connect and login to database
function bolt.init(auth)
  bolt.version = connection.connect()
  auth.neotype = 'dictionary'
  
  local packed = packer.pack(0x01, auth)
  local err = connection.write(packed)
  if err ~= nil then
    return nil, err
  end
  
  local msg, err = connection.read()
  if msg == nil then
    return nil, err
  end
  
  local signature, response = unpacker.unpack(msg)
  if signature == 0x70 then
    return response
  elseif signature == 0x7F then
    return nil, 'Failed'
  elseif signature == 0x7E then
    return nil, 'Ignored'
  else
    return nil, 'No response from server'
  end
end

-- Shortcut for run and pull, returns rows with associated field keys
function bolt.query(cypher, params, extra)
  local meta, rows, stats, err
  
  meta, err = bolt.run(cypher, params, extra)
  if meta == nil then
    return nil, err
  end
  
  rows, err = bolt.pull()
  if rows == nil then
    return nil, err
  end
  
  local output = {}
  if table.len(rows) > 1 then
    table.remove(rows)
    for _, r in ipairs(rows) do
      local row = {}
      for i, value in pairs(r) do
        row[meta.fields[i]] = value
      end
    
      table.insert(output, row)
    end
  end
  
  return output
end

-- Run query, returns meta informations
function bolt.run(cypher, params, extra)
  params = params or {}
  params.neotype = 'dictionary'
  extra = extra or {}
  extra.neotype = 'dictionary'
  
  local packed = packer.pack(0x10, cypher, params, extra)
  local err = connection.write(packed)
  if err ~= nil then
    return nil, err
  end
  
  local msg
  msg, err = connection.read()
  if msg == nil then
    return nil, err
  end
  
  local signature, response = unpacker.unpack(msg)
  if signature == 0x70 then
    return response
  elseif signature == 0x7F then
    if response == nil then
      return nil, 'Failed'
    else
      return nil, '[' .. response.code .. '] ' .. response.message
    end
  elseif signature == 0x7E then
    return nil, 'Ignored'
  else
    return nil, 'Unknown error'
  end
end

-- Pull records from last executed query, returns rows with indexed field keys and last record is stats
function bolt.pull(extra)
  if extra == nil then
    extra = {}
  end
  if extra.n == nil then
    extra.n = -1
  end
  extra.neotype = 'dictionary'
  
  local packed = packer.pack(0x3F, extra)
  local err = connection.write(packed)
  if err ~= nil then
    return nil, err
  end
  
  local output = {}
  local signature, response, msg
  repeat
    msg, err = connection.read()
    if msg == nil then
      return nil, err
    end
    
    signature, response = unpacker.unpack(msg)
    if signature == 0x70 or signature == 0x71 then
      table.insert(output, response)
    elseif signature == 0x7F then
      return nil, '[' .. response.code .. '] ' .. response.message
    elseif signature == 0x7E then
      return nil, 'Ignored'
    end
  until signature == 0x70
  
  return output
end

-- Start transaction
function bolt.begin(extra)
end

-- Commit transaction
function bolt.commit(extra)
end

-- Rollback transaction
function bolt.rollback(extra)
end

-- Reset connection to initial state
function bolt.reset()
end

-- Route
function bolt.route(routing)
end

-- Set requested bolt versions
function bolt.setVersions(...)
  connection.versions = {...}
end

-- Set host for connection
function bolt.setHost(ip, port)
  connection.ip = ip or '127.0.0.1'
  connection.port = port or 7687
end

return bolt
