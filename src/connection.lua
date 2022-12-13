local socket = require('socket')

local connection = {
  versions = { 4.4, 4.3, 4.2, 3 },
  ip = '127.0.0.1',
  port = 7687,
  secure = nil,
  timeout = 15
}

local client = nil

local function packVersions()
  local output = {}
  while #connection.versions < 4 do
    table.insert(connection.versions, 0)
  end

  for _, v in ipairs(connection.versions) do
    v = string.gsub(tostring(v), '%.', '')
    v = string.reverse(tostring(v))
    v = string.format('%04d', v)
    for r in string.gmatch(v, '[0-9]') do
      table.insert(output, string.pack('>B', r))
    end
  end

  return table.concat(output, '')
end

local function unpackVersion(msg)
  local output = {}
  for b in string.gmatch(msg, '.') do
    b = string.unpack('>B', b)
    table.insert(output, b)
  end

  while output[1] == 0 do
    table.remove(output, 1)
  end

  return string.reverse(table.concat(output, '.'))
end

local function bin2hex(...)
  local output = ''
  for i, v in ipairs({...}) do 
    local k = 1
    for b in string.gmatch(v, '.') do
      output = output .. string.format("%02x ", string.byte(b))
      
      if k % 4 == 0 then
        output = output .. '  '
      end
      k = k + 1
    end
  end
  return output
end

function connection.connect()
  client = nil

  local conn, err, result, sended, msg

  conn, err = socket.tcp()
  if conn == nil then
    return conn, err
  end

  result, err = conn:connect(connection.ip, connection.port)
  if result == nil then
    return result, err
  end
  
  conn:settimeout(connection.timeout)
  conn:setoption('keepalive', true)
  
  -- SSL if required https://github.com/brunoos/luasec/wiki
  if connection.secure ~= nil then
    local ssl = require('ssl')
    
    conn, err = ssl.wrap(conn, connection.secure)
    if err ~= nil then
      return nil, err
    end
    
    if connection.secure.dane then
      conn:setdane(connection.ip)
    end
    
    result, err = conn:dohandshake()
    if err ~= nil then
      return nil, err
    end
  end

  -- Handshake and Versions request
  sended, err = conn:send(string.char(0x60, 0x60, 0xB0, 0x17) .. packVersions())
  if sended == nil then
    return nil, err
  end

  -- Read version
  msg, err = conn:receive(4)
  if msg == nil then
    return nil, err
  end

  local version = unpackVersion(msg)
  if #version > 0 then
    client = conn
    return version
  else
    return nil
  end
end

-- Write to connection
-- Returns nil on success otherwise it's error
function connection.write(data)
  if client == nil then
    return 'Not connected'
  end
  
  local offset = 1
  
  repeat
    local chunk = string.sub(data, offset, offset + 65535 - 1)
    chunk = string.pack('>I2', #chunk) .. chunk
    if BOLT_DEBUG then
      print('C: ' .. bin2hex(chunk))
    end
    
    local sended, err = client:send(chunk)
    if err ~= nil then
      return err
    end
    -- substract chunk length
    offset = offset + sended - 2
  until offset >= #data
  
  
  if BOLT_DEBUG then
    print('C: 00 00')
  end
  client:send(string.char(0x00) .. string.char(0x00))

  return nil
end

-- Read next message from connection
function connection.read()
  if client == nil then
    return nil, 'Not connected'
  end
  
  local function receive(length)
    local output = ''
    while #output < length do
      output = output .. client:receive(length - #output)
    end
    return output
  end
  
  local header, length, err
  local msg = ''
  while true do
    header, err = client:receive(2)
    if header == nil then
      return nil, err
    end
    
    if string.byte(header, 1) == 0x00 and string.byte(header, 2) == 0x00 then
      break
    end
    
    length = string.unpack('>I2', header)
    msg = msg .. receive(length)
  end

  if BOLT_DEBUG then
    print('S: ' .. bin2hex(msg))
  end
  return msg
end

-- Close connection
function connection.close()
  if client ~= nil then
    client:close()
    client = nil
  end
end

-- Set timeout for existing and new connection
function connection.setTimeout(timeout)
  connection.timeout = timeout
  if client ~= nil then
    client:settimeout(timeout)
  end
end

return connection
