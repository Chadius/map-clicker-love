--[[ State required to track a Unit on a Map.
--]]

MapUnit={}
function MapUnit:new()
  return self
end
function MapUnit:load()
end
function MapUnit:draw()
  self.drawing:drawOnTile() -- TODO
end
