--[[ State required to track a Unit on a Map.
--]]

MapUnit={}
function MapUnit:new()
  self.drawing=nil
  self.column=nil
  self.row=nil
  return self
end
function MapUnit:load()
end
function MapUnit:update(dt)
end
function MapUnit:moveToTile(column, row)
  -- Indicate the unit should move to the given location on the map.
  self.column = column
  self.row = row
end
function MapUnit:draw()
  if self.column ~= nil and self.row ~= nil then
    self.drawing:drawOnTile(self.column, self.row)
  end
end
