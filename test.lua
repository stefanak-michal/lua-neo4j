package.path = package.path .. ';./src/?.lua'
local bolt = require('src.bolt')

function bin2hex(...)
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
            print( indent .. "[" .. pos .. '] => "' .. val .. '"', '(' .. type(val) .. ')' )
          else
            print( indent .. "[" .. pos .. "] => " .. tostring(val), '(' .. type(val) .. ')' )
          end
        end
      else
        print( indent..tostring(t), '(' .. type(t) .. ')' )
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

print('init')
dump(bolt.init({scheme = 'basic', principal = 'neo4j', credentials = 'nothing', user_agent = 'bolt-lua'}))

print('basic types')
local vars = {
  ['int'] = 123, 
  ['str'] = 'abc',
  ['flo'] = 43.65464,
  ['list'] = {['neotype'] = 'list', 34, 65},
  ['dict'] = {['neotype'] = 'dictionary', ['one'] = 1, ['two'] = 2},
  ['nul'] = nil,
  ['btrue'] = true,
  ['bfalse'] = false
}
local cypher = {}
for k, v in pairs(vars) do
  table.insert(cypher, '$' .. k .. ' AS ' .. k)
end
dump(bolt.query('RETURN ' .. table.concat(cypher, ','), vars))

print('reset')
dump(bolt.reset())

print('transaction')
dump( bolt.begin() )

print('run')
dump( bolt.run('CREATE (a:Test { name: $name }) RETURN a AS node', {['name'] = 'Foo'}) )
print('pull')
dump( bolt.pull() )

print('rollback')
dump( bolt.rollback() )


