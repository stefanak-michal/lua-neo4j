local socket = require("socket")
local ssl = require("ssl")

versions = {5}

function hex2bin(str)
  return (string.gsub(str, '..', function (cc)
    return string.char(tonumber(cc, 16))
  end))
end

function bin2hex(...)
  local output = ''
  for i, v in ipairs({...}) do 
    --print(i, v, utf8.codes(v))

    for j, b in utf8.codes(v) do
      output = output .. string.format("%02x ", b)
    end
  end
  return output
end

function packVersion()
  local output = ''
  while #versions < 4 do
    table.insert(versions, 0)
  end
  
  for i, v in ipairs(versions) do
    v = string.gsub(tostring(v), '%.', '')
    v = string.reverse(tostring(v))
    v = string.format('%04d', v)
    for r in string.gmatch(v, '[0-9]') do
      output = output .. string.pack('B', r)
    end
  end
  
  return output
end

function unpackVersion(msg)
  local output = {}
  for b in string.gmatch(msg, '.') do
    b, _ = string.unpack('B', b)
    table.insert(output, b)
  end
  
  while output[1] == 0 do
    table.remove(output, 1)
  end
  
  return string.reverse(table.concat(output, '.'))
end

--test = packVersion()
--print(bin2hex(test))
--os.exit()

conn, err = socket.tcp()
if conn == nil then
  print(err)
  os.exit()
end

result, err = conn:connect("127.0.0.1", 7687)
if result == nil then
  print(err)
  os.exit()
end
  
print('Connected to: ' .. conn:getsockname())

--client, err = socket.connect('127.0.0.1', 7687)
conn:settimeout(1)
conn:setoption('keepalive', true)


print('Handshake')
sended, err = conn:send(string.char(0x60, 0x60, 0xB0, 0x17))
if sended == nil then
  print(err)
  os.exit()
end
--print(conn:getstats())

print('Version request')
sended, err = conn:send(packVersion())
if sended == nil then
  print(err)
  os.exit()
end
--print(conn:getstats())

msg, err = conn:receive(4)
--print(conn:getstats())
if msg == nil then
  print(err)
  os.exit()
end

version = unpackVersion(msg)
print('Responded version: ' .. version)

conn:close()
