local bolt = {}

local connection = require('connection')
local packer = require('packer')
local unpacker = require('unpacker')

local function clone (t) -- deep-copy a table
    if type(t) ~= "table" then return t end
    local meta = getmetatable(t)
    local target = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            target[k] = clone(v)
        else
            target[k] = v
        end
    end
    setmetatable(target, meta)
    return target
end

function bolt.list(t)
  local new = clone(t)
  new.neotype = 'list'
  return new
end

function bolt.dictionary(t)
  local new = clone(t)
  new.neotype = 'dictionary'
  return new
end

function bolt.null()
  return {['neotype'] = 'null'}
end

local function processMessage(msg)
  local response = unpacker.unpack(msg)
  if unpacker.signature == 0x70 then
    return response
  elseif unpacker.signature == 0x7F then
    if response == nil then
      return nil, 'Failed'
    else
      return nil, '[' .. response.code .. '] ' .. response.message
    end
  elseif unpacker.signature == 0x7E then
    return nil, 'Ignored'
  else
    return nil, 'Unknown error'
  end
end


-- Connect and login to database
function bolt.init(auth)
  bolt.version = connection.connect()

  auth.neotype = 'dictionary'
  if auth.routing ~= nil then
    auth.routing.neotype = 'dictionary'
  end
  if auth.user_agent == nil then
    auth.user_agent = 'bolt-lua'
  end

  local packed = packer.pack(0x01, auth)
  local err = connection.write(packed)
  if err ~= nil then
    return nil, err
  end

  local msg
  msg, err = connection.read()
  if msg == nil then
    return nil, err
  end

  return processMessage(msg)
end

-- Shortcut for run and pull, returns rows with associated field keys
function bolt.query(cypher, params, extra)
  local meta, rows, err

  meta, err = bolt.run(cypher, params, extra)
  if meta == nil then
    return nil, err
  end

  rows, err = bolt.pull()
  if rows == nil then
    return nil, err
  end

  local output = {}
  if #rows > 1 then
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

  return processMessage(msg)
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
  local response, msg
  repeat
    msg, err = connection.read()
    if msg == nil then
      return nil, err
    end

    response = unpacker.unpack(msg)
    if unpacker.signature == 0x70 or unpacker.signature == 0x71 then
      -- clean up neotype null
      for k, v in pairs(response) do
        if type(v) == 'table' and v.neotype == 'null' then
          response[k] = nil
        end
      end
      table.insert(output, response)
    elseif unpacker.signature == 0x7F then
      return nil, '[' .. response.code .. '] ' .. response.message
    elseif unpacker.signature == 0x7E then
      return nil, 'Ignored'
    else
      return nil, 'Unknown error'
    end
  until unpacker.signature == 0x70

  return output
end

-- Discard waiting records (for pull) from last executed query
function bolt.discard(extra)
  if extra == nil then
    extra = {}
  end
  if extra.n == nil then
    extra.n = -1
  end
  extra.neotype = 'dictionary'

  local packed = packer.pack(0x2F, extra)
  local err = connection.write(packed)
  if err ~= nil then
    return nil, err
  end

  local msg
  msg, err = connection.read()
  if msg == nil then
    return nil, err
  end

  return processMessage(msg)
end

-- Start transaction
function bolt.begin(extra)
  extra = extra or {}
  extra.neotype = 'dictionary'

  local packed = packer.pack(0x11, extra)
  local err = connection.write(packed)
  if err ~= nil then
    return nil, err
  end

  local msg
  msg, err = connection.read()
  if msg == nil then
    return nil, err
  end

  return processMessage(msg)
end

-- Commit transaction
function bolt.commit()
  local packed = packer.pack(0x12)
  local err = connection.write(packed)
  if err ~= nil then
    return nil, err
  end

  local msg
  msg, err = connection.read()
  if msg == nil then
    return nil, err
  end

  return processMessage(msg)
end

-- Rollback transaction
function bolt.rollback()
  local packed = packer.pack(0x13)
  local err = connection.write(packed)
  if err ~= nil then
    return nil, err
  end

  local msg
  msg, err = connection.read()
  if msg == nil then
    return nil, err
  end

  return processMessage(msg)
end

-- Reset connection to initial state
function bolt.reset()
  local packed = packer.pack(0x0F)
  local err = connection.write(packed)
  if err ~= nil then
    return nil, err
  end

  local msg
  msg, err = connection.read()
  if msg == nil then
    return nil, err
  end

  return processMessage(msg)
end

-- Route
function bolt.route(routing, bookmarks, db)
  routing.neotype = 'dictionary'
  bookmarks.neotype = 'list'

  local packed = packer.pack(0x66, routing, bookmarks, db)
  local err = connection.write(packed)
  if err ~= nil then
    return nil, err
  end

  local msg
  msg, err = connection.read()
  if msg == nil then
    return nil, err
  end

  return processMessage(msg)
end

-- Set requested bolt versions
function bolt.setVersions(...)
  connection.versions = {...}
end

-- Set host for connection
function bolt.setHost(ip)
  connection.ip = ip or '127.0.0.1'
end

-- Set port for connection
function bolt.setPort(port)
  connection.port = port or 7687
end

-- Set SSL config for connection
-- https://github.com/brunoos/luasec/wiki/LuaSec-1.0.x#ssl_newcontext
function bolt.setSSL(params)
  connection.secure = params
end

-- Set timeout for connection ..default 15 seconds
function bolt.setTimeout(timeout)
  connection.setTimeout(timeout)
end

return bolt
