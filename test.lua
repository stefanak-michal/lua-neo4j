local bolt = require('src.bolt')

function bin2hex(...)
  local output = ''
  for i, v in ipairs({...}) do 
    --print(i, v, utf8.codes(v))

    for b in string.gmatch(v, '.') do
      output = output .. string.format("%02x ", string.byte(b))
    end
  end
  return output
end

response, err = bolt.init({type = 'dictionary', scheme = 'basic', principal = 'neo4j', credentials = 'nothing', user_agent = 'bolt-lua'})
if response == nil then
  print(err)
  os.exit()
end

print()
print()
for k, v in pairs(response) do
  print(k, v)
end
