describe('Main', function()
  local bolt = require('../src/bolt')
  math.randomseed(os.time())
  --_G['BOLT_DEBUG'] = true
  
  describe('registering custom assert functions', function()
    local function is_similar(state, arguments, level)
      if arguments[3] == nil then
        arguments[3] = 0.8
      end
      
      local n = 0
      for i = 1, math.min(#arguments[1], #arguments[2]), 1 do
        if string.sub(arguments[1], i, i) ~= string.sub(arguments[2], i, i) then
          break
        end
        n = i
      end
      
      if arguments[4] ~= nil then
        set_failure_message(state, arguments[4])
      end
      
      return (n / math.min(#arguments[1], #arguments[2])) >= arguments[3]
    end
    
    assert:register("assertion", "similar", is_similar, "assertion.matches.positive", "assertion.matches.negative")
  end)


  it('init #init', function()
    bolt.setHost('host.docker.internal')
    local meta, err = bolt.init({scheme = 'basic', principal = 'neo4j', credentials = 'nothing'})
    assert.is.truthy(meta, err)
    bolt.setTimeout(nil) -- we have some heavy tests and after init success set infinite timeout
  end)

  it('bool true #btrue', function()
    local result, err = bolt.query('RETURN $b AS b, toString($b) AS str', {['b'] = true})
    assert.is.truthy(result, err)
    assert.is_true(result[1].b)
    assert.are.equal(result[1].str, 'true')
  end)

  it('bool false #bfalse', function()
    local result, err = bolt.query('RETURN $b AS b, toString($b) AS str', {['b'] = false})
    assert.is.truthy(result, err)
    assert.is_false(result[1].b)
    assert.are.equal(result[1].str, 'false')
  end)

  it('null:nil #bnull', function()
    local result, err = bolt.query('RETURN $n AS n', {['n'] = bolt.null()})
    assert.is.truthy(result, err)
    assert.is.falsy(result[1].n)
  end)

  describe('integers #int', function()
    local function test_int(m, n)
      local num, dec = math.modf(m + (n - m) * math.random())
      if dec > 0.5 then
        num = num + 1
      end
      
      local result, err = bolt.query('RETURN $i AS int, toString($i) AS str', {['i'] = num})
      assert.is.truthy(result, err)
      assert.are.equal(result[1].int, num)
      assert.are.equal(result[1].str, tostring(num))
    end
    
    it('tiny int', function()
      for _ = 1, 10, 1 do test_int(-16, 127) end
    end)
    it('int8', function()
      for _ = 1, 10, 1 do test_int(-128, -17) end
    end)
    it('int16 +', function()
      for _ = 1, 10, 1 do test_int(128, 32767) end
    end)
    it('int16 -', function()
      for _ = 1, 10, 1 do test_int(-32768, -129) end
    end)
    it('int32 +', function()
      for _ = 1, 10, 1 do test_int(32768, 2147483647) end
    end)
    it('int32 -', function()
      for _ = 1, 10, 1 do test_int(-2147483648, -32769) end
    end)
    it('int64 +', function()
      for _ = 1, 10, 1 do test_int(2147483648, 9223372036854775807) end
    end)
    it('int64 -', function()
      for _ = 1, 10, 1 do test_int(-9223372036854775808, -2147483649) end
    end)
      
  end)

  it('float #float', function()
    for _ = 1, 10, 1 do
      local f = math.random()
      local result, err = bolt.query('RETURN $f AS float, toString($f) AS str', {['f'] = f})
      assert.is.truthy(result, err)
      assert.are.equal(result[1].float, f)
      assert.similar(result[1].str, tostring(f))
    end
  end)

  describe('strings #string', function()
    local charset = {}
    for i = 32, 122, 1 do table.insert(charset, string.char(i)) end
    
    local function test_string(size)
      local function random_string(length)
        local output = ''
        repeat
          output = output .. charset[math.random(1, #charset)]
        until #output == length
        return output
      end
      
      local s = random_string(size)
      local result, err = bolt.query('RETURN $s AS str', {['s'] = s})
      assert.is.truthy(result, err)
      assert.are.equal(s, result[1].str)
    end
    
    it('short', function() test_string(10) end)
    it('up to 255', function() test_string(200) end)
    it('up to 65 535', function() test_string(60000) end)
    it('up to 2 147 483 647', function() test_string(200000) end)
  end)

  describe('lists #list', function()
    local function test_list(size)
      local list = {['neotype'] = 'list'}
      for _ = 1, size do table.insert(list, math.random(1, 99)) end
      local result, err = bolt.query('RETURN $l AS list', {['l'] = list})
      assert.is.truthy(result, err)
      list.neotype = nil
      assert.are.same(list, result[1].list)
    end
      
    it('up to 15', function() test_list(10) end)
    it('up to 255', function() test_list(200) end)
    it('up to 65 535', function() test_list(60000) end)
    it('up to 2 147 483 647', function() test_list(200000) end)
  end)

  describe('dictionaries #dictionary', function()
    local function test_dict(size)
      local dict = {['neotype'] = 'dictionary'}
      for i = 1, size do dict[tostring(i)] = math.random(1, 99) end
      local result, err = bolt.query('RETURN $d AS dict', {['d'] = dict})
      assert.is.truthy(result, err)
      dict.neotype = nil
      assert.are.same(dict, result[1].dict)
    end
      
    it('up to 15', function() test_dict(10) end)
    it('up to 255', function() test_dict(200) end)
    it('up to 65 535', function() test_dict(60000) end)
    it('up to 2 147 483 647', function() test_dict(200000) end)
  end)
  
  describe('structures #structure', function()

    it('Node #node', function()
      bolt.begin()
      local result, err = bolt.query('CREATE (a:Test { name: $name }) RETURN a', {['name'] = 'Joe'})
      assert.is.truthy(result, err)
      assert.are.equals('Node', result[1].a.neotype)
      assert.are.equals('Joe', result[1].a.properties.name)
      assert.are.same({'Test'}, result[1].a.labels)
      bolt.rollback()
    end)

    it('Relationship #rel', function()
      bolt.begin()
      local result, err = bolt.query('CREATE (a:Test)-[rel:RELS { prop: $n }]->(b:Test) RETURN rel', {['n'] = 123})
      assert.is.truthy(result, err)
      assert.are.equals('Relationship', result[1].rel.neotype)
      assert.are.equals(123, result[1].rel.properties.prop)
      assert.are.same('RELS', result[1].rel.type)
      bolt.rollback()
    end)

    it('Path #path', function()
      bolt.begin()
      local result, err = bolt.query('CREATE p=(a:Test)-[rel:RELS { type: $n }]->(b:Test) RETURN p', {['n'] = 123})
      assert.is.truthy(result, err)
      assert.are.equals('Path', result[1].p.neotype)
      assert.are.equals(2, #result[1].p.nodes)
      assert.are.equals(1, #result[1].p.rels)
      bolt.rollback()
    end)
  
    describe('Temporal values #temporal', function()
      local function test_temporal(fn, type)
        local res1, res2, err
      
        res1, err = bolt.query('RETURN ' .. fn .. ' AS dt')
        assert.is.truthy(res1, err)
        assert.are.equals(type, res1[1].dt.neotype)
        
        res2, err = bolt.query('RETURN $dt AS dt', {['dt'] = res1[1].dt})
        assert.is.truthy(res2, err)
        assert.are.same(res1[1].dt, res2[1].dt)
      end
      
      it('Date #date', function() test_temporal('date()', 'Date') end)
      it('Time #time', function() test_temporal('time()', 'Time') end)
      it('DateTime #datetime', function() test_temporal('datetime("2015-07-21T21:40:32.142+01:00")', 'DateTime') end)
      it('LocalTime #localtime', function() test_temporal('localtime()', 'LocalTime') end)
      it('LocalDateTime #localdatetime', function() test_temporal('localdatetime()', 'LocalDateTime') end)
      it('DateTimeZoneId #timezone', function() test_temporal('datetime({timezone: "Europe/Prague"})', 'DateTimeZoneId') end)
      it('Duration #duration', function() test_temporal('duration({days: 14, hours: 16, minutes: 12})', 'Duration') end)
      
      it('Point2D #point2d', function() test_temporal('point({x: 2.3, y: 4.5})', 'Point2D') end)
      it('Point3D #point3d', function() test_temporal('point({x: 2.3, y: 4.5, z: 2})', 'Point3D') end)
    end)

  end)

end)
