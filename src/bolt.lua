local bolt = {}

local connection = require('src.connection')
local packer = require('src.packer')
local unpacker = require('src.unpacker')

function table.len(t)
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count
end

function bolt.init(auth)
  bolt.version = connection.connect()
  
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
    return nil, 'No message from server'
  end
end

function bolt.query(cypher, params, extra)
  --pack
  --connection.write
  --unpack
  --return
end

function bolt.begin(extra)
end

function bolt.commit(extra)
end

function bolt.rollback(extra)
end

function bolt.reset()
end

function bolt.route(routing)
end

function bolt.setVersions(...)
  connection.versions = {...}
end

function bolt.setHost(ip, port)
  connection.ip = ip or '127.0.0.1'
  connection.port = port or 7687
end

return bolt
