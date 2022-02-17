local socket = require('socket')
local ssl = require('ssl')

local connection = {}
connection.versions = { 4.4, 4.3, 3 }
connection.ip = '127.0.0.1'
connection.port = 7687
connection.auth = {}

local client = nil

function packVersions()
  local output = {}
  while #connection.versions < 4 do
    table.insert(connection.versions, 0)
  end

  for i, v in ipairs(connection.versions) do
    v = string.gsub(tostring(v), '%.', '')
    v = string.reverse(tostring(v))
    v = string.format('%04d', v)
    for r in string.gmatch(v, '[0-9]') do
      table.insert(output, string.pack('>B', r))
    end
  end

  return table.concat(output, '')
end

function unpackVersion(msg)
  local output = {}
  for b in string.gmatch(msg, '.') do
    b, _ = string.unpack('>B', b)
    table.insert(output, b)
  end

  while output[1] == 0 do
    table.remove(output, 1)
  end

  return string.reverse(table.concat(output, '.'))
end

function connection.connect()
  client = nil

  local conn, err, result, sended, msg

  conn, err = socket.tcp()
  if conn == nil then
    return conn, err
  end

  -- add ssl if required https://github.com/brunoos/luasec/wiki

  result, err = conn:connect(connection.ip, connection.port)
  if result == nil then
    return result, err
  end

  conn:settimeout(1)
  conn:setoption('keepalive', true)

  -- Handshake
  err = connection.write(string.char(0x60, 0x60, 0xB0, 0x17))
  if err ~= nil then
    return nil, err
  end

  -- Versions request
  err = connection.write(packVersions())
  if err ~= nil then
    return nil, err
  end

  -- Read version
  msg, err = connection.read(4)
  if msg == nil then
    return msg, err
  end

  local version = unpackVersion(msg)

  if #version > 0 then
    client = conn
    return version
  else
    return nil
  end
end

function connection.write(data)
  if client == nil or client:getpeername() == nil then
    return 'Not connected'
  end

  local sended, err = client:send(data)
  -- todo chunking

  return nil
end

function connection.read(length)
  if client == nil or client:getpeername() == nil then
    return nil, 'Not connected'
  end

  return client:receive(length)
  -- todo chunking
end

function connection.close()
  if client ~= nil and client:getpeername() ~= nil then
    client:close()
  end
end

return connection
