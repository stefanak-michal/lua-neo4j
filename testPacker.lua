local packer = require('src/packer')
local packed = packer.pack(0x10, { type = 'list', 5 })

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

print(bin2hex(packed))
