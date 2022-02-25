-- https://7687.org/packstream/packstream-specification-1.html#structure

local structures = {
  {
    ['signature'] = 0x4E,
    ['neotype'] = 'Node', 
    ['keys'] = {'id', 'labels', 'properties'},
    ['types'] = {'Integer', 'List', 'Dictionary'}
  },
  {
    ['signature'] = 0x52,
    ['neotype'] = 'Relationship', 
    ['keys'] = {'id', 'startNodeId', 'endNodeId', 'type', 'properties'},
    ['types'] = {'Integer', 'Integer', 'Integer', 'String', 'Dictionary'}
  },
  {
    ['signature'] = 0x72,
    ['neotype'] = 'UnboundRelationship', 
    ['keys'] = {'id', 'type', 'properties'},
    ['types'] = {'Integer', 'String', 'Dictionary'}
  },
  {
    ['signature'] = 0x50,
    ['neotype'] = 'Path',
    ['keys'] = {'nodes', 'rels', 'ids'},
    ['types'] = {'List', 'List', 'List'}
  },
  {
    ['signature'] = 0x44,
    ['neotype'] = 'Date',
    ['keys'] = {'days'},
    ['types'] = {'Integer'}
  },
  {
    ['signature'] = 0x54,
    ['neotype'] = 'Time', 
    ['keys'] = {'nanoseconds', 'tz_offset_seconds'},
    ['types'] = {'Integer', 'Integer'}
  },
  {
    ['signature'] = 0x74,
    ['neotype'] = 'LocalTime',
    ['keys'] = {'nanoseconds'},
    ['types'] = {'Integer'}
  },
  {
    ['signature'] = 0x46,
    ['neotype'] = 'DateTime', 
    ['keys'] = {'seconds', 'nanoseconds', 'tz_offset_seconds'},
    ['types'] = {'Integer', 'Integer', 'Integer'}
  },
  {
    ['signature'] = 0x66,
    ['neotype'] = 'DateTimeZoneId',
    ['keys'] = {'seconds', 'nanoseconds', 'tz_id'},
    ['types'] = {'Integer', 'Integer', 'String'}
  },
  {
    ['signature'] = 0x64,
    ['neotype'] = 'LocalDateTime',
    ['keys'] = {'seconds', 'nanoseconds'},
    ['types'] = {'Integer', 'Integer'}
  },
  {
    ['signature'] = 0x45,
    ['neotype'] = 'Duration', 
    ['keys'] = {'months', 'days', 'seconds', 'nanoseconds'},
    ['types'] = {'Integer', 'Integer', 'Integer', 'Integer'}
  },
  {
    ['signature'] = 0x58,
    ['neotype'] = 'Point2D',
    ['keys'] = {'srid', 'x', 'y'},
    ['types'] = {'Integer', 'Float', 'Float'}
  },
  {
    ['signature'] = 0x59,
    ['neotype'] = 'Point3D',
    ['keys'] = {'srid', 'x', 'y', 'z'},
    ['types'] = {'Integer', 'Float', 'Float', 'Float'}
  }
}

local M = {}

function M.bySignature(signature)
  for _, v in ipairs(structures) do
    if v.signature == signature then
      return v
    end
  end
  return nil
end

function M.byType(neotype)
  for _, v in ipairs(structures) do
    if v.neotype == neotype then
      return v
    end
  end
  return nil
end

return M
