-- https://7687.org/packstream/packstream-specification-1.html#structure

local structures = {
  {
    ['signature'] = 0x4E,
    ['neotype'] = 'Node', 
    ['id'] = 'Integer', 
    ['labels'] = 'List', 
    ['properties'] = 'Dictionary'
  },
  {
    ['signature'] = 0x52,
    ['neotype'] = 'Relationship', 
    ['id'] = 'Integer', 
    ['startNodeId'] = 'Integer', 
    ['endNodeId'] = 'Integer', 
    ['type'] = 'String', 
    ['properties'] = 'Dictionary'
  },
  {
    ['signature'] = 0x72,
    ['neotype'] = 'UnboundRelationship', 
    ['id'] = 'Integer', 
    ['type'] = 'String', 
    ['properties'] = 'Dictionary'
  },
  {
    ['signature'] = 0x50,
    ['neotype'] = 'Path', 
    ['nodes'] = 'List', 
    ['rels'] = 'List', 
    ['ids'] = 'List'
  },
  {
    ['signature'] = 0x44,
    ['neotype'] = 'Date',
    ['days'] = 'Integer'
  },
  {
    ['signature'] = 0x54,
    ['neotype'] = 'Time', 
    ['nanoseconds'] = 'Integer', 
    ['tz_offset_seconds'] = 'Integer'
  },
  {
    ['signature'] = 0x74,
    ['neotype'] = 'LocalTime',
    ['nanoseconds'] = 'Integer'
  },
  {
    ['signature'] = 0x46,
    ['neotype'] = 'DateTime', 
    ['seconds'] = 'Integer', 
    ['nanoseconds'] = 'Integer', 
    ['tz_offset_seconds'] = 'Integer'
  },
  {
    ['signature'] = 0x66,
    ['neotype'] = 'DateTimeZoneId',
    ['seconds'] = 'Integer',
    ['nanoseconds'] = 'Integer',
    ['tz_id'] = 'String'
  },
  {
    ['signature'] = 0x64,
    ['neotype'] = 'LocalDateTime',
    ['seconds'] = 'Integer', 
    ['nanoseconds'] = 'Integer'
  },
  {
    ['signature'] = 0x45,
    ['neotype'] = 'Duration', 
    ['months'] = 'Integer',
    ['days'] = 'Integer',
    ['seconds'] = 'Integer', 
    ['nanoseconds'] = 'Integer'
  },
  {
    ['signature'] = 0x58,
    ['neotype'] = 'Point2D',
    ['srid'] = 'Integer', 
    ['x'] = 'Float', 
    ['y'] = 'Float'
  },
  {
    ['signature'] = 0x59,
    ['neotype'] = 'Point3D',
    ['srid'] = 'Integer', 
    ['x'] = 'Float', 
    ['y'] = 'Float', 
    ['z'] = 'Float'
  }
}

local M = {}

function M.bySignature(signature)
  for i, v in ipairs(structures) do
    if v.signature == signature then
      return v
    end
  end
  return nil
end

function M.byType(neotype)
  for i, v in ipairs(structures) do
    if v.neotype == neotype then
      return v
    end
  end
  return nil
end

return M
