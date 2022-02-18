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

local function dump( t )
  local printTable_cache = {}

  local function sub_printTable( t, indent )
    if ( printTable_cache[tostring(t)] ) then
      print( indent .. "*" .. tostring(t) )
    else
      printTable_cache[tostring(t)] = true
      if ( type( t ) == "table" ) then
        for pos,val in pairs( t ) do
          if ( type(val) == "table" ) then
            print( indent .. "[" .. pos .. "] => " .. tostring( t ).. " {" )
            sub_printTable( val, indent .. string.rep( " ", string.len(pos)+8 ) )
            print( indent .. string.rep( " ", string.len(pos)+6 ) .. "}" )
          elseif ( type(val) == "string" ) then
            print( indent .. "[" .. pos .. '] => "' .. val .. '"' )
          else
            print( indent .. "[" .. pos .. "] => " .. tostring(val) )
          end
        end
      else
        print( indent..tostring(t) )
      end
    end
  end

  if ( type(t) == "table" ) then
    print( tostring(t) .. " {" )
    sub_printTable( t, "  " )
    print( "}" )
  else
    sub_printTable( t, "  " )
  end
end

local response, err

print()
response, err = bolt.init({scheme = 'basic', principal = 'neo4j', credentials = 'nothing', user_agent = 'bolt-lua'})
if response == nil then
  print(err)
  os.exit()
end
dump(response)

print()
response, err = bolt.query('RETURN $a as num, $s as str', {['a'] = 123, ['s'] = 'abc'})
if response == nil then
  print(err)
  os.exit()
end
dump(response)
