local bolt = {}

local connection = require('connection')
local packer = require('packer')
local unpacker = require('unpacker')

function bolt.init(auth)
  local version = connection.connect()
  --auth - pack it and write
  --connection.write()
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
