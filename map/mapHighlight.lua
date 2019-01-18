--[[ Higlight multiple coordinates on a map.
--]]

local MapHighlight = {}
MapHighlight.__index = MapHighlight

function MapHighlight:new()
  --[[ Create a new path.
  --]]
  local newHighlight = {}
  setmetatable(newHighlight,MapHighlight)

  -- A 2D matrix. If [column][map] is not nil, then that location was highlighted.
  newHighlight.highlights = {}

  return newHighlight
end
function MapHighlight:copyFromMapMatrix(matrix)
  --[[ Copy values from the given 2D matrix.
  --]]
end
function MapHighlight:flatten()
  --[[ Returns a list of {column, row} tables.
  -- Each item is a highlighted point.
  --]]
  return {}
end
