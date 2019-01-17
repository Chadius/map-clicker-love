local MapSelector={}
MapSelector.__index = MapSelector

function MapSelector:new()
  --[[ Create a new path.
  --]]
  local newSelector = {}
  setmetatable(newSelector,MapSelector)
  newSelector.column=nil
  newSelector.row=nil
  return newSelector
end
function MapSelector:selectTile(column, row)
  if column ~= nil then
    self.column = column
    self.row = row
  else
    -- If the user clicked off screen, deselect.
    self.column = nil
    self.row = nil
  end
end

return MapSelector
